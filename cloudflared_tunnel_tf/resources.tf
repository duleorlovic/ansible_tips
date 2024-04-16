resource "lxd_instance" "container1" {
  name  = "container1"
  image = "ubuntu-daily:22.04"
  # TF_VAR_created_by=$(whoami)@$(hostname):$(pwd)" terraform plan
  description = "created_by ${var.created_by}"

  config = {
    "boot.autostart" = true
    "cloud-init.user-data" = <<-EOF
#cloud-config
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo
    ssh_authorized_keys:
      - ${file("~/.ssh/id_rsa.pub")}
EOF
  }

  limits = {
    cpu = 2
  }

  provisioner "local-exec" {
    // If specifying an SSH key and user, add `--private-key <path to private key> -u var.name`
    # ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu  -i 10.89.228.42, playbook.yml
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu  -i ${self.ipv4_address}, playbook.yml"
  }

  depends_on = [
    local_file.tf_ansible_vars_file
  ]
}
