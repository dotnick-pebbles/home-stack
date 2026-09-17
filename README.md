# Automating Deployment
## Bootstrapping
### Install Proxmox VE (PVE)
See https://proxmox.com/en/products/proxmox-virtual-environment/get-started

SSH into the freshly installed PVE host as root.

Install git
```bash
apt install --yes git
```

### Build server
#### Create LXC
Still on the PVE host; clone the home-stack repo.
```bash
mkdir -p ~/git && \
git clone https://github.com/dotnick-pebbles/home-stack.git ~/git/home-stack
```
   \# curl -O https://raw.githubusercontent.com/dotnick-pebbles/home-stack/refs/heads/main/bootstrap/boostrap.env

Copy the sample env files.
```bash
cp ~/git/home-stack/bootstrap/sample.bootstrap.env ~/git/home-stack/bootstrap/bootstrap.env && \
cp ~/git/home-stack/env/sample.hosts.env ~/git/home-stack/env/hosts.env
```
Make sure to update 'password' in boostrap/bootstrap.env, as well as any other variables to suit your needs.

Run the setup script.
```bash
~/git/home-stack/bootstrap/setup_build_server.sh
```
