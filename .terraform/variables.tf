# define GCP authentication file path
variable "creds_file" {
  type        = string
  description = "GCP authentication file"
  default     = "~/.config/gcloud/application_default_credentials.json"
}

# define GCP region
variable "gcp_region" {
  type        = string
  description = "GCP region"
  default     = "us-central1"
}
# define GCP zone
variable "gcp_zone" {
  type        = string
  description = "GCP zone"
  default     = "us-central1-a"
}
# define GCP project id
variable "gcp_project" {
  type        = string
  description = "Project id"
  default     = "striking-theme-372017"
}

# this variable is used for resource naming
variable "project_alias" {
  type        = string
  description = "variable for resources naming"
  default     = "k8s-proj"
}

# define subnet cidr block
variable "subnet_cidr" {
  type        = string
  description = "The CIDR for the network subnet"
  default     = "10.2.0.0/16"
}

# define network routing mode
variable "net_rt_mode" {
  type        = string
  description = "network routing mode"
  default     = "GLOBAL"
}

# define firewall source ranges(global range here)
variable "frwll_src_range" {
  type        = list(any)
  description = "firewall source range"
  default     = ["0.0.0.0/0"]
}

# define input variables for vm options
variable "vms" {
  description = "Map of vm names to configuration."
  type = map(object({
    instance_type   = string,
    disk_size       = string,
    disk_type       = string,
    boot_disk_image = string,
    ssh_user        = string,
    ssh_pub_key     = string
  }))
}