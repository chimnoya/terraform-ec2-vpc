#Create S3 Bucket
resource "aws_s3_bucket" "techchak_s3_bucket" {
  bucket = "techchak-s3-bucket-nono"

  tags = {
    Name        = "techchak-s3-bucket"
    Environment = "test"
    Managed_by = "terraform"
  }
}

#Create an IAM Policy
resource "aws_iam_policy" "techchak-s3-policy" {
  name        = "S3-Bucket-Access-Policy"
  description = "Policy to provide permission to access S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
        ]
        Effect   = "Allow"
        Resource = [
            "${aws_s3_bucket.techchak_s3_bucket.arn}",
            "${aws_s3_bucket.techchak_s3_bucket.arn}/*"
            ]
      },
    ]
  })
}

#Create an IAM Role
resource "aws_iam_role" "techchak-role" {
  name = "techchak_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "RoleForEC2"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

#Attach the IAM Role to the IAM Policy
resource "aws_iam_policy_attachment" "techchak-attach" {
  name       = "techchak-attachment"
  roles      = [aws_iam_role.techchak-role.name]
  policy_arn = aws_iam_policy.techchak-s3-policy.arn
}

#Create an Instance Profile
resource "aws_iam_instance_profile" "techchak-profile" {
  name = "techchak_profile"
  role = aws_iam_role.techchak-role.name
}

#Create EC2 instance and Attach Instance Profile
resource "aws_instance" "techchak-instance" {
  instance_type = "t2.micro"
  ami = "ami-0b0dcb5067f052a63"
  iam_instance_profile = aws_iam_instance_profile.techchak-profile.name
  tags = {
    Name = "techchak-instance"
}  
}