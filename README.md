# pfsense-packer-proxmox

Create http folder before running the packer build
``` bash
sudo mkdir http
```
``` bash
packer build -var-file=variables.pkr.hcl -var-file=credentials.pkr.hcl pfSense.pkr.hcl
```
working on pfsense 2-7-2