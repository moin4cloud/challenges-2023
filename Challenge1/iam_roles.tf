variable "build_roles_list" {
    description = "The list of roles that build needs"
    type        = list(string)
    default = [
        "roles/run.developer",
        "roles/vpaccess.user",
        "roles/iam.serviceAccountUser",
        "roles/run.admin",
        "roles/secretmanager.secretAccessor",
        "roles/artifactregistry.admin",
    ]
}

resource "google_project_iam_member" "allbuild" {
    for_each   = toset(var.build_roles_list)
    project    = var.project_number
    role       = each.key
    member     = "serviceAccount:${local.sabuild}"
    depends_on = [google_project_service.all]
}