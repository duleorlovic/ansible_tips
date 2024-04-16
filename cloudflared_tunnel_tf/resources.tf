resource "lxd_instance" "container1" {
  name  = var.lxd_container_name
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
package_update: true
packages:
  - git
  - vim-nox
EOF
  }

  limits = {
    cpu = 2
  }

  provisioner "local-exec" {
    // If specifying an SSH key and user, add `--private-key <path to private key> -u var.name`
   command = <<-EOF
      while ! nc -z ${self.ipv4_address} 22; do
        echo "Waiting for SSH to be ready..."
        sleep 0.3
      done
      echo ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu  -i ${self.ipv4_address}, playbook.yml
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ubuntu  -i ${self.ipv4_address}, playbook.yml
    EOF
  }

  depends_on = [
    local_file.tf_ansible_vars_file
  ]
}
