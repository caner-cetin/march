> You will need a legitimate copy of Quake 3: Arena. It is currently available through Steam on Windows, or gog, or if you’d like it on-disc second-hand markets like Ebay may have copies.

place all paks (`pak0-8.pk3`) from game files under `files` folder here (`ansible`).

server setup:
```bash
# first, you need a RCON password, random generate like this:
openssl rand -hex 32
# then fill the files/rcon_password.cfg with your password.
# save the password for later, you will need it for our main backend.
vagrant up --provider vmware_fusion
vagrant ssh-config >> $HOME/.ssh/config
ansible-playbook playbooks/system-setup.yaml
```