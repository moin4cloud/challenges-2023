variable "gcp_service_list" {
    description = "The list of apis necessary for the project"
    type        = list(string)
    default = [
        "compute.googleapis.com",
        "cloudapis.googleapis.com",
        "vpcaccess.googleapis.com",
        "servicenetworking.googleapis.com",
        "cloudbuild.googleapis.com",
        "sql-component.googleapis.com",
        "sqladmin.googleapis.com",
        "storage.googleapis.com",
        "secretmanager.googleapis.com",
        "run.googleapis.com",
        "artifactregistry.googleapis.com",
        "redis.googleapis.com"
    ]
}

resource "google_project_service" "all" {
    for_each                   = toset(var.gcp_service_list)
    project                    = var.project_number
    service                    = each.key
    disable_on_destroy = false
}