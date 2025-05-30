> You will need a legitimate copy of Quake 3: Arena. It is currently available through Steam on Windows, or gog, or if you’d like it on-disc second-hand markets like Ebay may have copies.

place all paks (`pak0-8.pk3`) from game files under `files` folder here (`ansible`).

server setup:
```bash
# or move openssl call seperately, then fill the rcon_password yourself. or use a password of your own instead of random generated one.
# this will be password for your remote controller.
openssl rand -hex 32 >> playbooks/files/rcon_password.cfg 
vagrant up --provider vmware_fusion
vagrant ssh-config >> $HOME/.ssh/config
ansible-playbook playbooks/system-setup.yaml
```