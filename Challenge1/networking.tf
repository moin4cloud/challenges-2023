resource "google_compute_global_address" "google_managed_services_vpn_connector" {
    name          = "google-managed-services-vpn-connector"
    purpose       = "VPC_PEERING"
    address_type  = "INTERNAL"
    prefix_length = 16
    network       = local.defaultnetwork
    project       = var.project_id
    depends_on    = [google_project_service.all]
}
resource "google_service_networking_connection" "vpcpeerings" {
    network                 = local.defaultnetwork
    service                 = "servicenetworking.googleapis.com"
    reserved_peering_ranges = [google_compute_global_address.google_managed_services_vpn_connector.name]
}

resource "google_vpc_access_connector" "connector" {
    provider      = google-beta
    project       = var.project_id
    name          = "vpc-connector"
    ip_cidr_range = "10.0.0.0/28"
    network       = "default"
    region        = var.region
    depends_on    = [google_compute_global_address.google_managed_services_vpn_connector, google_project_service.all]
}