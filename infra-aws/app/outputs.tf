output "app_url" {
  value = "http://${aws_eip.frontend.public_ip}"
}

output "ssh_frontend" {
  value = "ssh -i ~/.ssh/asistenciau ubuntu@${aws_eip.frontend.public_ip}"
}

output "ssh_backend" {
  value = "ssh -i ~/.ssh/asistenciau ubuntu@${aws_instance.backend.public_ip}"
}