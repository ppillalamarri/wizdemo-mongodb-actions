# variables.tf
variable "key_name" {
  description = "The name of the key pair to use for the EC2 instance"
  type        = string
  default     = "wizdemokeypair" # Optional default value
}
