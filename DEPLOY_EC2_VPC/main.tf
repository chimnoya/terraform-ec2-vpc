#Create VPC
resource "aws_vpc" "nono_demo_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "nono_vpc"
  }
}


#Public Subnet
resource "aws_subnet" "nono_public_subnet" {
  vpc_id     = aws_vpc.nono_demo_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "nono_public_subnet"
  }
}

#Private Subnet
resource "aws_subnet" "nono_private_subnet" {
  vpc_id     = aws_vpc.nono_demo_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "nono_private_subnet"
  }
}


#Security Group
resource "aws_security_group" "nono_demo_sg" {
  name        = "nono_demo_sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.nono_demo_vpc.id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.nono_demo_vpc.cidr_block, "0.0.0.0/0"]
  }

 ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.nono_demo_vpc.cidr_block, "0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_hhtp_ssh"
  }
}

#Internet Gateway
resource "aws_internet_gateway" "nono_demo_igw" {
  vpc_id = aws_vpc.nono_demo_vpc.id

  tags = {
    Name = "nono_demo_igw"
  }
}

# #Internet Gateway Attachment
# resource "aws_internet_gateway_attachment" "demo_igw_attach" {
#   internet_gateway_id = aws_internet_gateway.nono_demo_igw.id
#   vpc_id              = aws_vpc.nono_demo_vpc.id
# }

#Elastic IP
resource "aws_eip" "demo_elastic_ip" {
  vpc      = true
}
  
#NAT GATEWAY
resource "aws_nat_gateway" "nono_demo_nat_gateway" {
  allocation_id = aws_eip.demo_elastic_ip.id
  subnet_id     = aws_subnet.nono_public_subnet.id 

  tags = {
    Name = "Demo NAT Gateway"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.nono_demo_igw]
}

#Route Tables
#Public Route
resource "aws_route_table" "nono_demo_vpc_public_RouteTable" {
  vpc_id = aws_vpc.nono_demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nono_demo_igw.id
  }

  tags = {
    Name = "vpc_Public_RouteTable"
  }
}

#Private Route
resource "aws_route_table" "nono_demo_vpc_private_RouteTable" {
  vpc_id = aws_vpc.nono_demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nono_demo_nat_gateway.id 
  }

  tags = {
    Name = "vpc_Private_RouteTable"
  }
}

#Route Table Association
#Public Route
resource "aws_route_table_association" "nono_demo_public_RouteTable_Assoc" {
  subnet_id      = aws_subnet.nono_public_subnet.id
  route_table_id = aws_route_table.nono_demo_vpc_public_RouteTable.id
}

#Private Route
resource "aws_route_table_association" "nono_demo_private_RouteTable_Assoc" {
  subnet_id      = aws_subnet.nono_private_subnet.id
  route_table_id = aws_route_table.nono_demo_vpc_private_RouteTable.id
}


#Create EC2
resource "aws_instance" "nono_EC2webserver" {
  ami = "ami-0b0dcb5067f052a63"
  instance_type = "t2.micro"
  key_name = "nono-demo"
  subnet_id = aws_subnet.nono_public_subnet.id
  vpc_security_group_ids = [aws_security_group.nono_demo_sg.id]
  associate_public_ip_address = true
  root_block_device {
    volume_type = "gp2"
    volume_size = "20"
    delete_on_termination = true
  }
  user_data = "${file("userData.sh")}"
  tags = {
    Name = "demoEC2WebServer"
  }
}
