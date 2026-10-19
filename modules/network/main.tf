resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags                 = { Name = "VPC-${terraform.workspace}" }
}

resource "aws_internet_gateway" "igw" { vpc_id = aws_vpc.main.id }

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.pub_subnets[count.index]
  availability_zone       = [var.availability_zone_a, var.availability_zone_b][count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "Public-${terraform.workspace}-${count.index}" }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.priv_subnets[count.index]
  availability_zone = [var.availability_zone_a, var.availability_zone_b][count.index]
  tags = {
    Name = "Private-${terraform.workspace}-${count.index}"
    Tier = "Private"
  }
}

resource "aws_eip" "nat" { domain = "vpc" }
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
}

resource "aws_network_acl" "main" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = { Name = "NACL-${terraform.workspace}" }
}

resource "aws_route_table" "pub" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "priv" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "pub" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.pub.id
}

resource "aws_route_table_association" "priv" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.priv.id
}

output "vpc_id" { value = aws_vpc.main.id }
output "public_subnets" { value = aws_subnet.public[*].id }
output "private_subnets" { value = aws_subnet.private[*].id }

/*
Esto es lo que iba en el main del proyecto, se agrega acà por el tema del network
################## VPC ##################

resource "aws_vpc" "VPCSeminario2VSCode"{
	cidr_block ="${var.vpc_cidr}"
	instance_tenancy ="default"
	enable_dns_hostnames = true
	enable_dns_support = true
	tags = {
		Name = "VPCSeminario2VSCode"
	}
}

################## SUBNET 1 ##################
resource "aws_subnet" "SUBNET1_Sem2_Front1VSCode"{
	vpc_id = aws_vpc.VPCSeminario2VSCode.id
	cidr_block = "${var.subnet_1_front1_cidr}"
	availability_zone = "${var.availability_zone_a}"
	map_public_ip_on_launch = true
	tags = {
		"Name" = "SUBNET1_Sem2_Front1VSCode"
		"ENV" = "DEV"
	}
	depends_on = [ 
		aws_vpc.VPCSeminario2VSCode 
	]
}

################## SUBNET 2 ##################
resource "aws_subnet" "SUBNET2_Sem2_Front2VSCode"{
	vpc_id = aws_vpc.VPCSeminario2VSCode.id
	cidr_block = "${var.subnet_2_front2_cidr}"
	availability_zone = "${var.availability_zone_b}"
	map_public_ip_on_launch = true
	tags = {
		"Name" = "SUBNET2_Sem2_Front2VSCode"
		"ENV" = "DEV"
	}
	depends_on = [ 
		aws_vpc.VPCSeminario2VSCode 
	]
}

################## SUBNET 3 ##################
resource "aws_subnet" "SUBNET3_Sem2_Back1VSCode"{
	vpc_id = aws_vpc.VPCSeminario2VSCode.id
	cidr_block = "${var.subnet_3_back1_cidr}"
	availability_zone = "${var.availability_zone_a}"
	tags = {
		"Name" = "SUBNET3_Sem2_Back1VSCode"
		"ENV" = "DEV"
	}
	depends_on = [ 
		aws_vpc.VPCSeminario2VSCode 
	]
}

################## SUBNET 4 ##################
resource "aws_subnet" "SUBNET4_Sem2_Back2VSCode"{
	vpc_id = aws_vpc.VPCSeminario2VSCode.id
	cidr_block = "${var.subnet_4_back2_cidr}"
	availability_zone = "${var.availability_zone_b}"
	tags = {
		"Name" = "SUBNET4_Sem2_Back2VSCode"
		"ENV" = "DEV"
	}
	depends_on = [ 
		aws_vpc.VPCSeminario2VSCode 
	]
}

################## SUBNET 5 ##################
resource "aws_subnet" "SUBNET5_Sem2_Pers1VSCode"{
	vpc_id = aws_vpc.VPCSeminario2VSCode.id
	cidr_block = "${var.subnet_5_pers1_cidr}"
	availability_zone = "${var.availability_zone_a}"
	tags = {
		"Name" = "SUBNET5_Sem2_Pers1VSCode"
		"ENV" = "DEV"
	}
	depends_on = [ 
		aws_vpc.VPCSeminario2VSCode 
	]
}

################## SUBNET 6 ##################
resource "aws_subnet" "SUBNET6_Sem2_Pers2VSCode"{
	vpc_id = aws_vpc.VPCSeminario2VSCode.id
	cidr_block = "${var.subnet_6_pers2_cidr}"
	availability_zone = "${var.availability_zone_b}"
	tags = {
		"Name" = "SUBNET6_Sem2_Pers2VSCode"
		"ENV" = "DEV"
	}
	depends_on = [ 
		aws_vpc.VPCSeminario2VSCode 
	]
}

################## INTERNET GATEWAY ##################
resource "aws_internet_gateway" "IG_Sem2VSCode" {
  vpc_id = aws_vpc.VPCSeminario2VSCode.id
  tags = {
	"Name" = "IG_Sem2VSCode"
  }
  depends_on = [ 
	aws_vpc.VPCSeminario2VSCode 
  ]
}

################## NAT GATEWAY ##################
resource "aws_eip" "EIP_Sem2VSCode_NatGW_1" {
  domain = "vpc"
  tags = {
	"Name" = "EIP_Sem2VSCode_NatGW_1"
  }
  depends_on = [ 
	aws_internet_gateway.IG_Sem2VSCode
  ]
}

resource "aws_nat_gateway" "NGW_Sem2VSCode_VP_1" {
  allocation_id = aws_eip.EIP_Sem2VSCode_NatGW_1.id
  subnet_id = aws_subnet.SUBNET1_Sem2_Front1VSCode.id
  connectivity_type = "public"
  tags = {
	"Name" = "NGW_Sem2VSCode_VP_1"
  }
  depends_on = [ 
	aws_eip.EIP_Sem2VSCode_NatGW_1
  ]  
}


################## ROUTE TABLE PUBLIC ##################
resource "aws_route_table" "RT_Sem2VSCode_VP_Public" {
  vpc_id = aws_vpc.VPCSeminario2VSCode.id
  route {
	cidr_block = "0.0.0.0/0"
	gateway_id = aws_internet_gateway.IG_Sem2VSCode.id
  }
  tags = {
	"Name" = "RT_Sem2VSCode_VP_Public"
  }
  depends_on = [
	aws_vpc.VPCSeminario2VSCode,
	aws_internet_gateway.IG_Sem2VSCode
  ]
}


################## ROUTE TABLE ASSOCIATION PUBLIC FRONT#########
resource "aws_route_table_association" "RTA_Sem2_VP_Public_Front1" {
  subnet_id = aws_subnet.SUBNET1_Sem2_Front1VSCode.id
  route_table_id = aws_route_table.RT_Sem2VSCode_VP_Public.id
  depends_on = [ 
	aws_subnet.SUBNET1_Sem2_Front1VSCode,
	aws_route_table.RT_Sem2VSCode_VP_Public
  ]
}

resource "aws_route_table_association" "RTA_Sem2_VP_Public_Front2" {
  subnet_id = aws_subnet.SUBNET2_Sem2_Front2VSCode.id
  route_table_id = aws_route_table.RT_Sem2VSCode_VP_Public.id
  depends_on = [ 
	aws_subnet.SUBNET2_Sem2_Front2VSCode,
	aws_route_table.RT_Sem2VSCode_VP_Public
  ]
}

################## ROUTE TABLE PRIVATE ##################
resource "aws_route_table" "RT_Sem2VSCode_VP_Private" {
  vpc_id = aws_vpc.VPCSeminario2VSCode.id
  route {
	cidr_block = "0.0.0.0/0"
	nat_gateway_id = aws_nat_gateway.NGW_Sem2VSCode_VP_1.id
  }
  tags = {
	"Name" = "RT_Sem2VSCode_VP_Private"
  }
  depends_on = [
	aws_vpc.VPCSeminario2VSCode,
	aws_nat_gateway.NGW_Sem2VSCode_VP_1
  ]
}

################## ROUTE TABLE ASSOCIATION PRIVATE BACK#########
resource "aws_route_table_association" "RTA_Sem2_VP_Private_Back1" {
  subnet_id = aws_subnet.SUBNET3_Sem2_Back1VSCode.id
  route_table_id = aws_route_table.RT_Sem2VSCode_VP_Private.id
  depends_on = [ 
	aws_subnet.SUBNET3_Sem2_Back1VSCode,
	aws_route_table.RT_Sem2VSCode_VP_Private
  ]
}

resource "aws_route_table_association" "RTA_Sem2_VP_Private_Back2" {
  subnet_id = aws_subnet.SUBNET4_Sem2_Back2VSCode.id
  route_table_id = aws_route_table.RT_Sem2VSCode_VP_Private.id
  depends_on = [ 
	aws_subnet.SUBNET4_Sem2_Back2VSCode,
	aws_route_table.RT_Sem2VSCode_VP_Private
  ]
}

resource "aws_route_table_association" "RTA_Sem2_VP_Private_Pers1" {
  subnet_id = aws_subnet.SUBNET5_Sem2_Pers1VSCode.id
  route_table_id = aws_route_table.RT_Sem2VSCode_VP_Private.id
  depends_on = [ 
	aws_subnet.SUBNET5_Sem2_Pers1VSCode,
	aws_route_table.RT_Sem2VSCode_VP_Private
  ]
}

resource "aws_route_table_association" "RTA_Sem2_VP_Private_Pers2" {
  subnet_id = aws_subnet.SUBNET6_Sem2_Pers2VSCode.id
  route_table_id = aws_route_table.RT_Sem2VSCode_VP_Private.id
  depends_on = [ 
	aws_subnet.SUBNET6_Sem2_Pers2VSCode,
	aws_route_table.RT_Sem2VSCode_VP_Private
  ]
}

############# Network ACL #############

resource "aws_network_acl" "NACL-Sem2VP_Public" {
  vpc_id = aws_vpc.VPCSeminario2VSCode.id
  subnet_ids = [aws_subnet.SUBNET1_Sem2_Front1VSCode.id, aws_subnet.SUBNET2_Sem2_Front2VSCode.id]
  tags = {
    "Name" = "NACL-Sem2VP_Public"
  }
}

resource "aws_network_acl_rule" "NACL-Sem2VP_Public_Outbound" {
  network_acl_id = aws_network_acl.NACL-Sem2VP_Public.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "NACL-Sem2VP_Public_Inbound" {
  network_acl_id = aws_network_acl.NACL-Sem2VP_Public.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}
*/