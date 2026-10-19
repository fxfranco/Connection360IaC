variable "vpc_cidr" {
  description = "Rango CIDR para la VPC"
  type        = string
}

variable "pub_subnets" {
  description = "Lista de CIDRs para subredes públicas"
  type        = list(string)
}

variable "priv_subnets" {
  description = "Lista de CIDRs para subredes privadas"
  type        = list(string)
}

variable "availability_zone_a" {
  description = "Lista de CIDRs para subredes privadas"
  type        = string
}

variable "availability_zone_b" {
  description = "Lista de CIDRs para subredes privadas"
  type        = string
}


/*
# SUBNET 1 CIDR Block
variable "vpc_cidr_global"{
    description = "Ip de la VPC principal"
    type = string
}

# SUBNET 1 CIDR Block
variable "subnet_1_front1_cidr"{
    description = "Ip publica para el front 1"
    type = string
}

# SUBNET 2 CIDR Block
variable "subnet_2_front2_cidr"{
	description = "Ip publica para el front 2"
    type = string
}

# SUBNET 3 CIDR Block
variable "subnet_3_back1_cidr"{
	description = "Ip privada para el back 1"
    type = string
}

# SUBNET 4 CIDR Block
variable "subnet_4_back2_cidr"{
	description = "Ip privada para el back 2"
    type = string
}

# SUBNET 5 CIDR Block
variable "subnet_5_pers1_cidr"{
    description = "Ip privada para el pers 1"
    type = string
}

# SUBNET 6 CIDR Block
variable "subnet_6_pers2_cidr"{
    description = "Ip privada para el pers 2"
    type = string
}
*/

/*
########## Internet Gateway ##########
variable "igw_vp_name" {
    description = "Internet Gateway"
    type = string
}


########## NAT Gateway 1 - Elastic IP + NAT (Front 1) ##########
variable "eip1_vp_name" {
    description = "EIP-LabVP-NatGW-1"
    type = string
}

variable "natgw1_vp_name" {
    description = "NAT Gateway"
    type = string
}

########## Route Table - Public ##########
variable "rt_public_vp_name" {
    description = "RT-LabVP-Public"
    type = string
}

########## Route Table - Private ##########
variable "rt_private_vp_name" {
    description = "RT-LabVP-Private"
    type = string
}
*/