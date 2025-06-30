# Create a VPC
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16" # Private IP range
    enable_dns_support = true # Enable DNS resolution
    enable_dns_hostnames = true # Resolve public DNS hostnames to private IP addresses

    tags = {
        Name = "CreatedByTerraform"
    }
}

data "aws_availability_zones" "available" {} # All available AZs in the region
# Create a subnet
resource "aws_subnet" "public" {
    vpc_id            = aws_vpc.main.id # VPC ID
    cidr_block        = "10.0.0.0/24" # Private subnet mask range
    availability_zone = data.aws_availability_zones.available.names[0] // AZs
    map_public_ip_on_launch = true # Assign public IPs to instances in this subnet

    tags = {
      Name = "CreatedByTerraform"
    }
}

#Crate Internet Gateway (IGW)
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id # VPC ID

    tags = {
        Name = "CreatedByTerraform"
    }
}

#Create route table
resource "aws_route_table" "main" {
    vpc_id = aws_vpc.main.id # VPC ID

    route {
        cidr_block = "0.0.0.0/0" # Route to all IPs
        gateway_id = aws_internet_gateway.main.id # Internet Gateway ID
    }

    tags = {
        Name = "CreatedByTerraform"
    }
}

# Create a route table association
resource "aws_route_table_association" "main" {
    subnet_id      = aws_subnet.public.id # Subnet ID
    route_table_id = aws_route_table.main.id # Route Table ID
}


# Create private subnet for RDS
resource "aws_subnet" "private" {
    vpc_id            = aws_vpc.main.id # VPC ID
    cidr_block        = "10.0.2.0/24" # Private subnet mask range
    availability_zone = data.aws_availability_zones.available.names[0] // AZs
    map_public_ip_on_launch = false # Do not assign public IPs to instances in this subnet
    tags = {
        Name = "CreatedByTerraform"
    }
}


# Create private subnet for RDS
# RDS needs at least two subnets in different availability zones for high availability
resource "aws_subnet" "private2" {
    vpc_id            = aws_vpc.main.id # VPC ID
    cidr_block        = "10.0.3.0/24" # Private subnet mask range
    availability_zone = data.aws_availability_zones.available.names[1] // AZs
    map_public_ip_on_launch = false # Do not assign public IPs to instances in this subnet
    tags = {
        Name = "CreatedByTerraform"
    }
}

# Create a security group for EC2 instances
resource "aws_security_group" "ec2_sg" {
    vpc_id = aws_vpc.main.id # VPC ID

    ingress {
        from_port   = 22 # SSH port
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere
    }

    ingress {
        from_port   = 8000
        to_port     = 8000
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] 
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "CreatedByTerraform"
    }
}

# Create a security group for RDS
resource "aws_security_group" "rds_sg" {
    vpc_id = aws_vpc.main.id # VPC ID

    ingress {
        from_port   = 5432 # PostgreSQL port
        to_port     = 5432
        protocol    = "tcp"
        security_groups = [aws_security_group.ec2_sg.id] # Allow access from EC2 security group
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "CreatedByTerraform"
    }
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon
}

# Create a subnet group for RDS
resource "aws_db_subnet_group" "main" {
    name       = "terraform-rds-subnet-group"
    subnet_ids = [
        aws_subnet.private.id,
        aws_subnet.private2.id
    ] # Private subnet for RDS

    tags = {
    Name = "CreatedByTerraform"
    }
}

# Create RDS instance
resource "aws_db_instance" "postgres" {
    identifier              = "terraform-postgres-db"
    engine                  = "postgres"
    engine_version          = "15.7"
    instance_class          = "db.t3.micro"
    allocated_storage       = 20
    db_name                 = "postgres"
    username                = var.db_username
    password                = var.db_password
    vpc_security_group_ids  = [aws_security_group.rds_sg.id]
    storage_encrypted       = true
    db_subnet_group_name    = aws_db_subnet_group.main.name
    publicly_accessible     = false # Not accessible from the internet
    skip_final_snapshot     = true # Skip final snapshot on deletion (fine for dev)
    multi_az                = false # Single AZ deployment for simplicity

    tags = {
        Name = "CreatedByTerraform"
    }
}

# Create a EC2 instance
resource "aws_instance" "terraform_instance" {
    depends_on = [aws_db_instance.postgres]
    count         = 1
    ami           = data.aws_ami.amazon_linux.id # Use the latest Amazon Linux AMI
    instance_type = "t3.micro"
    subnet_id = aws_subnet.public.id # Public subnet
    vpc_security_group_ids = [aws_security_group.ec2_sg.id] # Security group for EC2
    key_name      = var.public_key # SSH key pair name
    
    user_data = <<-EOF
        #!/bin/bash
        sudo yum update -y
        sudo amazon-linux-extras install docker -y
        sudo service docker start
        sudo usermod -a -G docker ec2-user
        docker pull ghcr.io/konstantinosloukaidis/terraform-devops:latest
        docker run -p 8000:8000 \
            -e DB_HOST="${aws_db_instance.postgres.address}" \
            -e DB_USER="${var.db_username}" \
            -e DB_PASSWORD="${var.db_password}" \
            -e DB_PORT="${var.db_port}" \
            -e DB_NAME="${var.db_name}" \
            ghcr.io/konstantinosloukaidis/terraform-devops:latest
        EOF
    
    tags = {
        Name = "CreatedByTerraform"
    }
}