module "my_ec2" {
  source = "../modules/ec2-instance"

  instance_name   = var.instance_name
  instance_type   = var.instance_type
  launch_template_id = var.launch_template_id
  ami_id          = var.ami_id
  vpc_id          = var.vpc_id
  subnet_id       = var.subnet_id
  key_name        = var.key_name
}
