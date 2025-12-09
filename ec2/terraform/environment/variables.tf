variable "vpc_id" {}
variable "subnet_id" {}
variable "launch_template_id" {
    default = ""
}
variable "ami_id" {
    default = ""
}
variable "instance_name" {
    default = ""
}
variable "instance_type" {}
variable "key_name" {}