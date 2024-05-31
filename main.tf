//This Terraform Template creates 4 Ansible Machines on EC2 Instances
//Ansible Machines will run on Red Hat Enterprise Linux 9 with custom security group
//allowing SSH (22), 5000, 3000 and 5432 connections from anywhere.
//User needs to select appropriate variables form "tfvars" file when launching the instance.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  #  secret_key = ""
  #  access_key = ""
}

# resource "aws_instance" "control_node" {
#   ami = var.myami
#   instance_type = var.controlinstancetype
#   key_name = var.mykey
#   iam_instance_profile = aws_iam_instance_profile.ec2full.name
#   vpc_security_group_ids = [aws_security_group.tf-sec-gr.id]
#   tags = {
#     Name = "ansible_control"
#     stack = "ansible_project"
#   }
# }

resource "aws_instance" "nodes" {
  ami = var.myami
  instance_type = var.instancetype
  count = var.num
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  key_name = var.mykey
  vpc_security_group_ids = [aws_security_group.tf-sec-gr.id]
  tags = {
    Name = "ansible_${element(var.tags, count.index )}"
    stack = "ansible_project"
    environment = "development"
  }
  user_data = file("userdata.sh")
}

# resource "aws_iam_role" "ec2full" {
#   name = "projectec2full-${var.user}"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Sid    = ""
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       },
#     ]
#   })

#   managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2FullAccess"]
# }

# resource "aws_iam_instance_profile" "ec2full" {
#   name = "projectec2full-${var.user}"
#   role = aws_iam_role.ec2full.name
# }

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "tf-sec-gr" {
  name = "${var.mysecgr}-${var.user}"
  vpc_id = data.aws_vpc.default.id
  tags = {
    Name = var.mysecgr
  }

  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5000
    protocol    = "tcp"
    to_port     = 5000
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    protocol    = "tcp"
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5432
    protocol    = "tcp"
    to_port     = 5432
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecr_repository" "my_ecr_repo" {
  name                 = "my-ecr-repo"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

output "repository_url" {
  value = aws_ecr_repository.my_ecr_repo.repository_url
}


# resource "null_resource" "config" {
#   depends_on = [aws_instance.control_node]
#   connection {
#     host = aws_instance.control_node.public_ip
#     type = "ssh"
#     user = "ec2-user"
#     private_key = file("~/.ssh/${var.mykey}.pem")
#     # Do not forget to define your key file path correctly!
#   }

#   provisioner "file" {
#     source = "./ansible.cfg"
#     destination = "/home/ec2-user/.ansible.cfg"
#   }

#   provisioner "file" {
#     source = "./inventory_aws_ec2.yml"
#     destination = "/home/ec2-user/inventory_aws_ec2.yml"
#   }

#   provisioner "file" {
#     # Do not forget to define your key file path correctly!
#     source = "~/.ssh/${var.mykey}.pem"
#     destination = "/home/ec2-user/${var.mykey}.pem"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo hostnamectl set-hostname Control-Node",
#       "sudo yum install -y python3",
#       "sudo yum install -y python3-pip",
#       "pip3 install --user ansible",
#       "pip3 install --user boto3",
#       "chmod 400 ${var.mykey}.pem"
#     ]
#   }

# }

# output "controlnodeip" {
#   value = aws_instance.control_node.public_ip
# }

# output "privates" {
#   value = aws_instance.control_node.*.private_ip
# }

provider "aws" {
  region = "us-west-2" # Kullanmak istediğiniz AWS bölgesini belirtin
}
# ECR Full Access politikasının tanımlanması
data "aws_iam_policy_document" "ecr_full_access" {
  statement {
    actions = [
      "ecr:*",
    ]
    resources = ["*"]
  }
}
# IAM rolünün oluşturulması
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role_with_ecr_full_access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
# ECR Full Access politikasının IAM rolüne eklenmesi
resource "aws_iam_role_policy" "ec2_role_policy" {
  name   = "ec2_role_policy"
  role   = aws_iam_role.ec2_role.id
  policy = data.aws_iam_policy_document.ecr_full_access.json
}
# # EC2 instanslarının oluşturulması
# resource "aws_instance" "agent_nodes" {
#   count         = 3 # 3 adet EC2 instansı oluştur
#   ami           = "ami-12345678" # Agent node için uygun bir AMI ID'si belirtin
#   instance_type = "t2.micro" # Agent node için uygun bir instance tipi belirtin
#   key_name      = "jenkins-key" # Agent node'da kullanılacak olan SSH anahtar çiftinin adını belirtin
#   iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
#   tags = {
#     Name = "agent_node_${count.index}"
#   }
# }
# IAM rolü için instance profile oluşturulması
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile_with_ecr_full_access"
  role = aws_iam_role.ec2_role.name
}