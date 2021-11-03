variable "state_bucket_name" {
  type    = string
  default = null
}

variable "state_lock_table_name" {
  type    = string
  default = "tf-lock"
}