resource "local_file" "tf_ansible_vars_file" {
  content = <<-DOC
    # Ansible vars_file containing variable values from Terraform.
    tunnel_id: ${cloudflare_tunnel.auto_tunnel.id}
    account: ${var.cloudflare_account_id}
    tunnel_name: ${cloudflare_tunnel.auto_tunnel.name}
    secret: ${base64sha256(random_password.tunnel_secret.result)}
    zone: ${var.cloudflare_zone}
    DOC

  filename = "./tf_ansible_vars_file.yml"
}
