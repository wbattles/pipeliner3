terraform {
  backend "s3" {
    bucket         = "tf-state-pipeline-bucket"
    key            = "ec2/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}

module "my_ec2" {
  source = "../modules/ec2-instance"

  instance_name   = var.instance_name
  instance_type   = var.instance_type
  launch_template_id = var.launch_template_id != "" ? var.launch_template_id : null
  ami_id          = var.ami_id
  vpc_id          = var.vpc_id
  subnet_id       = var.subnet_id
  key_name        = var.key_name
}
