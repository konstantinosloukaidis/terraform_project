variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "profile" {
  type    = string
}

variable "public_key" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_port" {
  type = number
  default = 5432
}

variable "db_name" {
  type = string
  default = "postgres"
}