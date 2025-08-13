# terraform/outputs.tf

output "service_urls" {
  description = "The URLs of the deployed App Runner services."
  value = {
    for name, service in aws_apprunner_service.main_services :
    name => service.service_url
  }
}