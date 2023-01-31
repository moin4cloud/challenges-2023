resource "google_redis_instance" "rediscache" {
    authorized_network      = local.defaultnetwork
    connect_mode            = "DIRECT_PEERING"
    location_id             = var.zone
    memory_size_gb          = 1
    name                    = "${var.basename}-cache"
    project                 = var.project_id
    redis_version           = "REDIS_6_X"
    region                  = var.region
    reserved_ip_range       = "10.137.125.88/29"
    tier                    = "BASIC"
    transit_encryption_mode = "DISABLED"
    depends_on              = [google_project_service.all]
}