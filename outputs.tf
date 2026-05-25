output "data_engineer_role_arn" {
  description = "ARN of the DataEngineerRole."
  value       = module.data_engineer_role.arn
}

output "glue_service_role_arn" {
  description = "ARN of the GlueServiceRole."
  value       = module.glue_service_role.arn
}
