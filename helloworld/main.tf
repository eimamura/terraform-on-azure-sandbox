variable "content" {
  default = "use input variables default value."
}
variable "filename" {
  default = "default_input.txt"
}
resource "local_file" "input_sample" {
  content  = var.content
  filename = var.filename
}
output "debug_print" {
  value = "${var.content} to ${var.filename}"
}
