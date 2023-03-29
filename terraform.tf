provider "aws " {
  region = "us-east-2"
}

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "newvpc"
  }
}

resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "publicsubnet"
  }

}

resource "aws_subnet" "pvtsub" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "privatesub"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "ig"
  }
}

resource "aws_route_table" "rtpub" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "10.0.1.0/24"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_eip" "lb" {
  vpc      = true
}


resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.lb.id
  subnet_id     = aws_subnet.pubsub.id

  tags = {
    Name = "gw NAT"
  }
}

resource "aws_route_table" "rtpvt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }
}  

resource "aws_route_table_association" "pubass" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.rtpub.id
}

resource "aws_route_table_association" "pubass" {
  subnet_id      = aws_subnet.pvtsub.id
  route_table_id = aws_route_table.rtpvt.id
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_instance" "publicmachine" {
    ami                          = "ami-02f97949d306b597a"
    instance_type                = "t2.micro"
    subnet_id                    = aws_subnet.pubsub.id
    key_name                     = "terraform"
    vpc_security_group_ids       = ["${aws_security_group.allow_all.id}"]  
    associate_public_ip_address  = true
}

resource "aws_instance" "private" {
    ami                          = "ami-02f97949d306b597a"
    instance_type                = "t2.micro"
    subnet_id                    = aws_subnet.privatesub.id
    key_name                     = "terraform"
    vpc_security_group_ids       = ["${aws_security_group.allow_all.id}"]  
    associate_public_ip_address  = true
}


