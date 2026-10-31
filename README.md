# Connection360 en AWS Academy (Terraform + Docker)

Despliega las imágenes Docker de Connection360 en AWS usando solo servicios disponibles en la licencia
académica (VPC, EC2, EBS, ALB, NAT). Todo corre en **contenedores Docker** y la configuración de cada
contenedor sale de un archivo de variables.

## Qué se crea

```
                         Internet
                            │ HTTP :80  (HTTPS :443 opcional con certificado ACM)
                      ┌─────▼─────┐
                      │    ALB    │  subredes públicas A y B
                      └─────┬─────┘
                            │ :8080  (health check /health)
                ┌───────────▼───────────┐
                │ gateway  172.20.0.10  │  subred pública A  · Connection360.ApiGateway (YARP)
                └───────┬───────┬───────┘
          :8080         │       │         :8080
     ┌──────────────────▼─┐   ┌─▼───────────────────────┐
     │ api  172.20.0.138  │   │ notification 172.20.0.202│   subredes privadas A y B
     │ Connection360.Api  │   │ Connection360Notification│
     └─────────┬──────────┘   └───────────┬─────────────┘
               │   etl 172.20.0.140       │
               │   Etl.Orchestrator       │
               │   + Etl.App              │
               └────────────┬─────────────┘
                            ▼
              ┌──────────────────────────────┐
              │ data  172.20.0.139           │  subred privada A
              │ PostgreSQL · MongoDB         │  disco EBS persistente montado en /data
              │ Zookeeper · Kafka · Alembic  │
              └──────────────────────────────┘
```

| Instancia | Contenedores | Subred | Tipo (por defecto) |
|---|---|---|---|
| `gateway` | Connection360.ApiGateway | pública A | t3.small |
| `api` | Connection360.Api | privada A | t3.medium |
| `notification` | Connection360Notification.Api | privada B | t3.small |
| `etl` | Connection360.Etl.Orchestrator (+ Etl.App manual) | privada A | t3.small |
| `data` | PostgreSQL, MongoDB, Zookeeper, Kafka, migraciones Alembic | privada A | t3.large + EBS 50 GiB |

Las IP privadas son **fijas** (se calculan de los CIDR de `environments/dev.tfvars`), así las instancias se
encuentran entre sí sin DNS y no cambian cuando AWS Academy detiene y arranca las instancias.

Reglas de red (grupos de seguridad, mínimo privilegio): internet → ALB(80/443) → gateway(8080) →
api/notification(8080); api, notification y etl → datos (Postgres 5432, Mongo 27017, Kafka 29092 solo api y
notification, señal de migraciones 5499); SSH solo desde tu IP al gateway y desde el gateway al resto (el gateway
hace de salto/bastión).

### Por qué quedó así (AWS Academy)

- **Solo servicios básicos**: no se crean roles IAM ni se usan servicios gestionados que la licencia suele
  bloquear (MSK, DocumentDB, etc.). PostgreSQL, MongoDB y Kafka corren como contenedores, igual que en tu
  `Connection360DataBase`, en una instancia con un volumen EBS **separado** (los datos sobreviven si la
  instancia se reemplaza).
- El EFS del lab k3s ya no se usa: una base de datos sobre NFS no es recomendable.
- **Estado nuevo** (`connection360/terraform.tfstate`): no toca el lab k3s anterior. El código del lab k3s
  (compute/security/storage originales) quedó en `legacy-k3s-lab/` solo como referencia.
- Gateway en subred pública con IP pública (para SSH y salto); el resto en subredes privadas con salida por NAT
  (descargan Docker e imágenes al arrancar).

## Prerrequisitos

1. Terraform ≥ 1.10 (el backend usa `use_lockfile`) y AWS CLI.
2. Credenciales del Learner Lab en el perfil `seminario2` (**cambian en cada sesión**): en AWS Academy abre
   *AWS Details → AWS CLI* y copia `aws_access_key_id`, `aws_secret_access_key` y `aws_session_token` en
   `~/.aws/credentials` (perfil `[seminario2]`).
3. El key pair `KP-Sem2` (o el que pongas en `key_name`) ya existe en la región.
4. **Imágenes en Docker Hub** de los 5 componentes + la de migraciones:
   - Componentes: `./deploy/build-images.ps1 -Push` (en la raíz de Connection360ApiCore).
   - Migraciones: ver `Connection360DataBase/postgres_db/deploy-migrations-image.md`
     (`./build-migrations-image.ps1 -Push`).
   - Las versiones deben coincidir con las de `environments/dev.tfvars`. Para usar el flag
     `ExternalApi__AllowInvalidServerCertificate` las imágenes del ETL deben estar reconstruidas.
5. Tu IP pública en `my_ip` (`curl ifconfig.me`) — si cambia, actualiza y vuelve a aplicar.

## Despliegue

```powershell
cd Terraform.AWS

# 1) Secretos (no se versiona)
Copy-Item secrets.auto.tfvars.example secrets.auto.tfvars
notepad secrets.auto.tfvars        # completa contraseñas, JWT, Auth0, SMTP, APIs externas...

# 2) Revisa environments/dev.tfvars (versiones de imágenes, CORS del front, my_ip...)

# 3) Terraform
terraform init -reconfigure        # -reconfigure porque cambió la key del estado
terraform fmt -recursive
terraform validate
terraform plan  -var-file=environments/dev.tfvars -out=tfplan
terraform apply tfplan
```

Al terminar, los *outputs* muestran `alb_dns`, la IP del gateway y los comandos SSH.
El arranque completo tarda ~8-15 minutos (instalar Docker, descargar imágenes, migraciones). Cuando termine:

```bash
curl http://<alb_dns>/health          # responde desde el gateway
```

## Cómo se arranca cada instancia (user_data)

1. Instala Docker y el plugin de Compose (con verificación SHA-256) y, si definiste credenciales, hace `docker login`.
2. Escribe `/opt/connection360/docker-compose.yml` y `.env` (con tus variables) y levanta los contenedores.
3. **Datos**: monta el EBS en `/data` (lo formatea solo la primera vez), pone ahí `data-root` de Docker, levanta
   Postgres (crea el rol `connection360apicore` y `apicore_user` con `db-init/01-init.sh`), Mongo, Zookeeper y
   Kafka, **ejecuta `alembic upgrade head`** en un contenedor y, solo si termina bien, abre el puerto 5499.
4. **api / notification / etl** esperan (máx. `wait_for_data_seconds`) a Postgres-migraciones, Mongo y Kafka antes de
   levantar sus contenedores. Si algo no responde a tiempo, avisan en el log y siguen (los contenedores se
   reintentan solos con `restart: unless-stopped`).

Logs: `/var/log/connection360-bootstrap.log` y `/var/log/cloud-init-output.log` en cada instancia.

## Operación

```bash
# SSH (los comandos exactos están en el output ssh_comandos)
ssh -i KP-Sem2.pem ec2-user@<gateway_public_ip>
ssh -i KP-Sem2.pem -J ec2-user@<gateway_public_ip> ec2-user@172.20.0.138    # api

sudo docker ps
sudo docker logs -f connection360_api
cd /opt/connection360 && sudo docker compose ps

# Migraciones otra vez (instancia de datos)
sudo /opt/connection360/run-migrations.sh

# Corrida manual del ETL (instancia etl)
cd /opt/connection360 && sudo docker compose run --rm etl-app
```

**Actualizar la versión de una imagen**: cambia la versión en `dev.tfvars` y `terraform apply`. Las instancias
sin estado (gateway, api, notification, etl) se **reemplazan** con el nuevo `user_data`. La instancia de datos
**no** se reemplaza por cambios de `user_data` ni de AMI (para no perder el stack en marcha): para cambiar algo allí
entra por SSH, edita `/opt/connection360/.env` y ejecuta `sudo /opt/connection360/redeploy.sh`.

## Variables y secretos

- No secretos: `environments/dev.tfvars`. Secretos: `secrets.auto.tfvars` (plantilla `secrets.auto.tfvars.example`).
- Los valores se escriben entre comillas simples en el `.env` de cada instancia, por eso **no pueden contener `'`
  ni saltos de línea** (Terraform lo valida antes de crear nada). Las contraseñas de Postgres/Mongo solo admiten
  `A-Z a-z 0-9 . _ ~ -` (mín. 12) porque viajan dentro de URLs y cadenas de conexión.
- **Sincronización de usuarios Auth0 → Notification** (`user_sync_*` y `mongo_basic_user_collection` en `dev.tfvars`,
  sin secretos nuevos): `Connection360.Api` lee los usuarios de Auth0 al arrancar y luego cada `user_sync_interval_minutes`,
  y los publica por lotes en el tópico `user_sync_topic` (Kafka lo crea solo: `KAFKA_AUTO_CREATE_TOPICS_ENABLE`).
  `Connection360Notification.Api` los consume con su propio grupo (`user_sync_group_id`, por defecto
  `<kafka_group_id>-users`) y los guarda sin duplicados en la colección `mongo_basic_user_collection`
  (`basicUserData`). La aplicación M2M de Auth0 necesita los scopes `read:users`, `update:users`, `read:roles`,
  `create:role_members` y `delete:role_members` (sin `read:roles` o `read:role_members` Auth0 responde 403
  «Insufficient scope» al consultar el rol de un usuario). De cada usuario se envían el id de Auth0, su correo y, de su
  `user_metadata`, `document`, `fullName` y `phone.number`. Auth0 solo permite paginar los primeros 1000 usuarios
  de `GET /users`; el Api lo registra como advertencia si se alcanza ese tope.
- **Caché de coordenadas** (`coordinates_cache_*` en `dev.tfvars`, sin secretos): `Connection360.Api` guarda en memoria las
  coordenadas de OpenStreetMap del detalle de envíos para no consultar a Nominatim en cada petición. `coordinates_cache_max_size_mb`
  (10 por defecto, ~16.000 lugares) es el tope de memoria; al llenarse se descartan primero las entradas más viejas. Se envía al
  contenedor como `CoordinatesCache__*`; `coordinates_cache_enabled = false` la desactiva. Requiere una imagen del Api que ya
  incluya la caché.
- Los secretos quedan en el `user_data` de las instancias y en el estado de Terraform (S3 cifrado). Trata el bucket
  del estado y el acceso SSH como sensibles. Nada de esto va dentro de las imágenes.

## Costos y limpieza

Consumen crédito del lab mientras existan: **NAT Gateway**, **ALB**, 5 instancias EC2 y el volumen EBS.
Para liberarlos: `terraform destroy -var-file=environments/dev.tfvars` — **borra también el volumen con los datos de
Postgres/Mongo/Kafka**. Haz respaldo antes (`pg_dump`, `mongodump`) si los necesitas.

## Limitaciones conocidas

- **APIs externas del ETL (equipo Windows)**: desde AWS no se alcanza una IP de LAN (`192.168.x.x`). Las URL de
  `external_apis` deben ser accesibles desde internet/VPN/túnel (la salida del ETL sale por la IP de la NAT).
- **HTTPS**: sin dominio no hay certificado público. El ALB atiende HTTP :80; si tu front es HTTPS, el navegador
  bloqueará las llamadas HTTP (contenido mixto). Opciones: certificado importado en ACM (`acm_certificate_arn`) o
  un dominio con certificado ACM. Quedan pendientes antes de exponer a internet: reemplazar los clientes de
  demostración de `/connect/token` del gateway y rotar los secretos que estén en `appsettings.Development.json`.
- **Sin alta disponibilidad**: una sola instancia de datos y una de cada servicio (suficiente para el laboratorio).
- **Kafka**: un solo broker, sin autenticación ni TLS (red privada con grupos de seguridad).
- El código de Notification **no escribe en Postgres** hoy (sus métricas van a MongoDB por el módulo de
  observabilidad); se le abrió el acceso a Postgres y se le pasa la cadena de conexión por si se necesita.
- No se pudo ejecutar `terraform validate/plan` en el entorno donde se escribió este código (sin acceso al
  registro de Terraform): ejecútalos tú antes del primer `apply` y revisa el plan.
