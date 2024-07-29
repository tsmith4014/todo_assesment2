
# Query the latest Amazon Linux 2 AMI ID
data "aws_ssm_parameter" "latest_amazon_linux_2" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Security Group for Backend Server
resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  description = "Security group for backend server"
  vpc_id      = var.vpc_id

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP Access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance for Backend Server
resource "aws_instance" "backend_server" {
  ami                    = data.aws_ssm_parameter.latest_amazon_linux_2.value
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  tags = {
    Name        = "backend-server"
    Team        = "mobile-app"
    Type        = "backend"
    Environment = "dev"
  }

  iam_instance_profile = aws_iam_instance_profile.ec2_s3_profile.name
}

# S3 bucket resource
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = var.bucket_name

  tags = {
    Name = "frontend"
  }
}

# S3 bucket CORS configuration
resource "aws_s3_bucket_cors_configuration" "frontend_bucket_cors" {
  bucket = aws_s3_bucket.frontend_bucket.bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# S3 Bucket Ownership Controls
resource "aws_s3_bucket_ownership_controls" "frontend_bucket_ownership" {
  bucket = aws_s3_bucket.frontend_bucket.bucket

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "frontend_bucket_access_block" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 Bucket ACL
resource "aws_s3_bucket_acl" "frontend_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.frontend_bucket_ownership,
    aws_s3_bucket_public_access_block.frontend_bucket_access_block,
  ]

  bucket = aws_s3_bucket.frontend_bucket.id
  acl    = "public-read"
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "frontend_bucket_website_config" {
  bucket = aws_s3_bucket.frontend_bucket.bucket

  index_document {
    suffix = "index.html"
  }
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:GetObjectTagging"
        ]
        Resource = [
          "${aws_s3_bucket.frontend_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Output the S3 bucket website URL
output "s3_bucket_website_url" {
  value = aws_s3_bucket_website_configuration.frontend_bucket_website_config.website_endpoint
}

# Output the EC2 instance public IP
output "ec2_instance_public_ip" {
  value = aws_instance.backend_server.public_ip
}






# # This Terraform configuration file defines the infrastructure resources for a DevOps project.
# # It creates the following resources:
# # - Security groups for the backend server and database server
# # - EC2 instances for the backend server and database server using a custom module
# # - An S3 bucket for the frontend application
# # - CORS configuration, ownership controls, public access block, ACL, website configuration, and policy for the S3 bucket

# # Security Group for Backend Server
# resource "aws_security_group" "backend_sg" {
#   name        = "backend-sg"
#   description = "Security group for backend server"
#   vpc_id      = var.vpc_id

#   # SSH Access
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # HTTP Access
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# # Security Group for Database Server
# resource "aws_security_group" "database_sg" {
#   name        = "database-sg"
#   description = "Security group for database server"
#   vpc_id      = var.vpc_id

#   # SSH Access
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   # MySQL Access from the Backend Server's IP
#   ingress {
#     from_port   = 3306
#     to_port     = 3306
#     protocol    = "tcp"
#     cidr_blocks = ["${module.backend_server.instance_public_ips[0]}/32"] # Convert IP to CIDR block
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# # Define backend and database modules
# module "backend_server" {
#   vpc_id                  = var.vpc_id
#   source                  = "./modules/ubuntu_servers"
#   instance_count          = 1
#   security_group_id       = aws_security_group.backend_sg.id
#   subnet_id               = var.subnet_id
#   key_name                = var.key_name
#   server_type             = "backend"
#   instance_tags           = {
#     Team        = "mobile-app"
#     Type        = "backend"
#     Environment = "dev"
#   }
#   iam_instance_profile_name = aws_iam_instance_profile.ec2_s3_profile.name
# }

# module "database_server" {
#   vpc_id                  = var.vpc_id
#   source                  = "./modules/ubuntu_servers"
#   instance_count          = 1
#   security_group_id       = aws_security_group.database_sg.id
#   subnet_id               = var.subnet_id
#   key_name                = var.key_name
#   server_type             = "database"
#   instance_tags           = {
#     Team        = "mobile-app"
#     Type        = "database"
#     Environment = "dev"
#   }
# }

# # S3 bucket resource
# resource "aws_s3_bucket" "frontend_bucket" {
#   bucket = "vegas-todo-bucket"

#   tags = {
#     Name        = "frontend"
#   }
# }

# # S3 bucket CORS configuration
# resource "aws_s3_bucket_cors_configuration" "frontend_bucket_cors" {
#   bucket = aws_s3_bucket.frontend_bucket.bucket

#   cors_rule {
#     allowed_headers = ["*"]
#     allowed_methods = ["GET", "PUT", "POST", "DELETE"]
#     allowed_origins = ["https://vegas-todo-bucket.s3.us-east-2.amazonaws.com/index.html"] #string geren from terrafrom output stretch
#     expose_headers  = ["ETag"]
#     max_age_seconds = 3000
#   }
# }

# # S3 Bucket Ownership Controls
# resource "aws_s3_bucket_ownership_controls" "frontend_bucket_ownership" {
#   bucket = aws_s3_bucket.frontend_bucket.bucket

#   rule {
#     object_ownership = "BucketOwnerPreferred"
#   }
# }

# # S3 Bucket Public Access Block
# resource "aws_s3_bucket_public_access_block" "frontend_bucket_access_block" {
#   bucket = aws_s3_bucket.frontend_bucket.id

#   block_public_acls       = false
#   block_public_policy     = false
#   ignore_public_acls      = false
#   restrict_public_buckets = false
# }

# # S3 Bucket ACL
# resource "aws_s3_bucket_acl" "frontend_bucket_acl" {
#   depends_on = [
#     aws_s3_bucket_ownership_controls.frontend_bucket_ownership,
#     aws_s3_bucket_public_access_block.frontend_bucket_access_block,
#   ]

#   bucket = aws_s3_bucket.frontend_bucket.id
#   acl    = "public-read"
# }

# # S3 Bucket Website Configuration
# resource "aws_s3_bucket_website_configuration" "frontend_bucket_website_config" {
#   bucket = aws_s3_bucket.frontend_bucket.bucket

#   index_document {
#     suffix = "index.html"
#   }
# }

# # S3 Bucket Policy
# resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
#   bucket = aws_s3_bucket.frontend_bucket.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = "*"
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:PutObjectAcl",
#           "s3:DeleteObject",
#           "s3:GetObjectTagging"
#         ]
#         Resource = [
#           "${aws_s3_bucket.frontend_bucket.arn}/*"
#         ]
#       }
#     ]
#   })
# }