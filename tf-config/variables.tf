variable "project_id" {
  type = string
  default = "kcuartero-crc-tf"
}

variable "region" {
  type = string
  default = "us-central1"
}

variable "project_number" {
  type = string
  default = "457324236736"
}

variable "public_key" {
    type = string
    default = "gcp_access/kcuartero-crc-tf-bb80eed0b9fa.json"
}

variable "index" {
  type = string
  default = "/Users/kcuartero/Documents/Documents - Kevin’s MacBook Pro/Cloud Resume Challenge/kkcuartero_crc/frontEnd/index.html"
}

variable "updateFunction" {
  type = string
  default = "/Users/kcuartero/Documents/Documents - Kevin’s MacBook Pro/Cloud Resume Challenge/kkcuartero_crc/frontEnd/updateVisitorCount.js"
}

variable "style_css" {
  type = string
  default = "/Users/kcuartero/Documents/Documents - Kevin’s MacBook Pro/Cloud Resume Challenge/kkcuartero_crc/frontEnd/style.css"
}

variable "cors" {
  type = string
  default = "/Users/kcuartero/Documents/Documents - Kevin’s MacBook Pro/Cloud Resume Challenge/kkcuartero_crc/frontEnd/cors.json"
}