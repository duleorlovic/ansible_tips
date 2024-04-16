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
