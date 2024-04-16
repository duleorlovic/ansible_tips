# Create lxd container and install cloudflared tunnel using ansible

Based on
https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/deploy-tunnels/deployment-guides/ansible/


Create `terraform.tfvars`
```
# terraform.tfvars
# https://developers.cloudflare.com/fundamentals/api/get-started/create-token/ with Cloudflare Tunnel and DNS permissions.
cloudflare_zone           = "trk.in.rs"
cloudflare_zone_id        = "asd..."
cloudflare_account_id     = "asd..."
cloudflare_email          = "email@..."
cloudflare_token          = "asd..."

# this is also used for dns, so use only alphanumeric and hyphens: my-app.trk.in.rs and ssh-my-app.trk.in.rs
lxd_container_name        = "my-app"
```

Run terraform
```
rerraform init
TF_VAR_created_by="$(whoami)@$(hostname):$(pwd)" terraform plan
TF_VAR_created_by="$(whoami)@$(hostname):$(pwd)" terraform apply -auto-approve
```

Test connection from lxd host
```
ssh ubuntu@"$(get_container_ip container1)" cat .ssh/authorized_keys
```

From machine you want to ssh you need to install `brew install cloudflared` tool
and configure ssh to use it
```
# .ssh/config
# https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/use-cases/ssh/
Host ssh_app.trk.in.rs
  ProxyCommand /home/linuxbrew/.linuxbrew/bin/cloudflared access ssh --hostname %h
```

and connect with
```
ssh ubuntu@ssh_app.trk.in.rs
```
