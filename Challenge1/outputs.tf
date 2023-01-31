output "region" {
	value = var.region
	description = "Google Cloud Region"
}

output "project_id" {
	value = var.project_id
	description = "Google Cloud Project ID"
}

output "endpoint" {
  value       = google_cloud_run_service.fe.status[0].url
  description = "URL of the front end which we want to surface to the user"
}

output "sqlservername" {
  value       = google_sql_database_instance.primary.name
  description = "Name of the database that we randomly generated."
}