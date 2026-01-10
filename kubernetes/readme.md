## setup kubernetes cluster

Salin dan jalankan perintah ini di terminal untuk mengaktifkan semua script:

```bash
#!/bin/bash
curl -sL https://raw.githubusercontent.com/itsanla/system/refs/heads/main/kubernetes/kube-config.sh | bash
```
```bash
curl -sL https://raw.githubusercontent.com/itsanla/system/refs/heads/main/kubernetes/kube-master.sh | bash
```
```bash
curl -sL https://raw.githubusercontent.com/itsanla/system/refs/heads/main/kubernetes/kube-storage.sh | bash
```
```bash
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```
