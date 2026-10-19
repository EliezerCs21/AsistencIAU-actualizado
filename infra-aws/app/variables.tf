variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "asistenciau"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "my_ip" {
  type        = string
  description = "Tu IP pública, para permitir SSH solo desde ahí"
}

variable "public_key_path" {
  type    = string
  default = "~/.ssh/asistenciau.pub"
}

variable "repo_url" {
  type    = string
  default = "https://github.com/luzmarinacadima/AsistencIAU-actualizado.git"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "admin_password" {
  type      = string
  sensitive = true
}

# "0" mientras uses HTTP; "1" si más adelante pones HTTPS
variable "session_secure" {
  type    = string
  default = "0"
}