resource "google_sql_database_instance" "primary" {
    name="${var.basename}-db-${random_id.id.hex}"
    database_version = "MYSQL_5_7"
    region           = var.region
    project          = var.project_id
    settings {
        tier                  = "db-g1-small"
        disk_autoresize       = true
        disk_autoresize_limit = 0
        disk_size             = 15
        disk_type             = "PD_SSD"
        ip_configuration {
            ipv4_enabled    = false
            private_network = local.defaultnetwork
        }
        location_preference {
            zone = var.zone
        }
    }
    deletion_protection = false
    depends_on = [
        google_project_service.all,
        google_service_networking_connection.vpcpeerings
    ]
    # This handles loading the schema after the database installs.
    provisioner "local-exec" {
        working_dir = "${path.module}/build/database"
        command     = "./load_schema.sh ${var.project_id} ${google_sql_database_instance.primary.name}"
    }
}

resource "google_artifact_registry_repository" "registry_app" {
    provider      = google-beta
    format        = "DOCKER"
    location      = var.region
    project       = var.project_id
    repository_id = "${var.basename}-repo"
    depends_on    = [google_project_service.all]
}

resource "google_secret_manager_secret" "redishost" {
    project = var.project_number
    replication {
        automatic = true
    }
    secret_id  = "redishost"
    depends_on = [google_project_service.all]
}
resource "google_secret_manager_secret_version" "redishost" {
    enabled     = true
    secret      = "projects/${var.project_number}/secrets/redishost"
    secret_data = google_redis_instance.rediscache.host
    depends_on  = [google_project_service.all, google_redis_instance.rediscache, google_secret_manager_secret.redishost]
}
resource "google_secret_manager_secret" "sqlhost" {
    project = var.project_number
    replication {
        automatic = true
    }
    secret_id  = "sqlhost"
    depends_on = [google_project_service.all]
}
resource "google_secret_manager_secret_version" "sqlhost" {
    enabled     = true
    secret      = "projects/${var.project_number}/secrets/sqlhost"
    secret_data = google_sql_database_instance.primary.private_ip_address
    depends_on  = [google_project_service.all, google_sql_database_instance.primary, google_secret_manager_secret.sqlhost]
}

resource "null_resource" "cloudbuild_api" {
  provisioner "local-exec" {
    working_dir = "${path.module}/build/middleware"
    command     = "gcloud builds submit . --substitutions=_REGION=${var.region},_BASENAME=${var.basename}"
  }
  depends_on = [
    google_artifact_registry_repository.registry_app,
    google_secret_manager_secret_version.redishost,
    google_secret_manager_secret_version.sqlhost,
    google_project_service.all
  ]
}

resource "google_cloud_run_service" "api" {
    name     = "${var.basename}-api"
    location = var.region
    project  = var.project_id

    template {
        spec {
            containers {
                image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.basename}-app/api"
                env {
                    name = "REDISHOST"
                    value_from {
                        secret_key_ref {
                            name = google_secret_manager_secret.redishost.secret_id
                            key  = "latest"
                        }
                    }
                }
                env {
                    name = "demo_host"
                    value_from {
                        secret_key_ref {
                        name = google_secret_manager_secret.sqlhost.secret_id
                        key  = "latest"
                        }
                    }
                }
                env {
                    name  = "demo_user"
                    value = "demo_user"
                }
                env {
                    name  = "demo_pass"
                    value = "demo_pass"
                }
                env {
                    name  = "demo_name"
                    value = "demo"
                }
                env {
                    name  = "REDISPORT"
                    value = "6379"
                }
            }
        }
        metadata {
            annotations = {
                "autoscaling.knative.dev/maxScale"        = "1000"
                "run.googleapis.com/cloudsql-instances"   = google_sql_database_instance.primary.connection_name
                "run.googleapis.com/client-name"          = "terraform"
                "run.googleapis.com/vpc-access-egress"    = "all"
                "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.id
            }
        }
    }
    autogenerate_revision_name = true
    depends_on = [
        null_resource.cloudbuild_api,
        google_project_iam_member.secretmanager_secretAccessor
    ]
} 

resource "google_cloud_run_service_iam_policy" "noauth_api" {
    location    = google_cloud_run_service.api.location
    project     = google_cloud_run_service.api.project
    service     = google_cloud_run_service.api.name
    policy_data = data.google_iam_policy.noauth.policy_data
}

resource "null_resource" "cloudbuild_fe" {
    provisioner "local-exec" {
        working_dir = "${path.module}/build/frontend"
        command     = "gcloud builds submit . --substitutions=_REGION=${var.region},_BASENAME=${var.basename}"
    }
    depends_on = [
        google_artifact_registry_repository.registry_app,
        google_cloud_run_service.api
    ]
}

resource "google_cloud_run_service" "fe" {
    name     = "${var.basename}-fe"
    location = var.region
    project  = var.project_id
    template {
        spec {
            containers {
                image = "${var.region}-docker.pkg.dev/${var.project_id}/${var.basename}-app/fe"
                ports {
                    container_port = 80
                }
            }
        }
    }
    depends_on = [null_resource.cloudbuild_fe]
}

resource "google_cloud_run_service_iam_policy" "noauth_fe" {
    location    = google_cloud_run_service.fe.location
    project     = google_cloud_run_service.fe.project
    service     = google_cloud_run_service.fe.name
    policy_data = data.google_iam_policy.noauth.policy_data
}