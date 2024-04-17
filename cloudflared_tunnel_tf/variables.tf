# Cloudflare variables
variable "cloudflare_zone" {
  description = "Domain used to expose the GCP VM instance to the Internet"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Zone ID for your domain"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Account ID for your Cloudflare account"
  type        = string
  sensitive   = true
}

variable "cloudflare_email" {
  description = "Email address for your Cloudflare account"
  type        = string
  sensitive   = true
}

variable "cloudflare_token" {
  description = "Cloudflare API token created at https://dash.cloudflare.com/profile/api-tokens"
  type        = string
  sensitive   = true
}

# lxc variables
variable "lxd_container_name" {
  type          = string
  description   = "Name of the container"
}

variable "public_key_file" {
   type        = string
   description = "Path to the public SSH key file. Generate with: ssh-keygen -f my-key"
   default     = "my-key.pub"  # Default as empty string indicates that only local ~/.ssh/id_rsa.pub will be added
}

variable "created_by" {
    type        = string
    description = <<-HERE_DOC
      Username and path of the person who applied this configuration.
      Run terraform with with variable:

        TF_VAR_created_by=$(whoami)@$(hostname):$(pwd)" terraform plan

      so later you can see the description of resource:

        lxc config show example-container | grep description:

    HERE_DOC
    default = "Not Defined"
}
