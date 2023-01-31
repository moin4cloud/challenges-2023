variable "project_id" {
  type        = string
  description = "The project ID"
}

variable "project_number" {
    type    = number
    description = "The project number"
}

variable "region" {
  type        = string
  description = "The Compute Region"
}

variable "zone" {
  type        = string
  description = "The Compute Zone"
}

variable "basename" {
    type    = string
    description = "Base name of this application deployment"
    default = "three-tier-app"
}

variable "labels" {
  type        = map(string)
  description = "A map of labels to apply to contained resources."
  default     = { "three-tier-app" = true }
}

variable "enable_apis" {
  type        = string
  description = "To enable underlying apis in this solution"
  default     = true
}