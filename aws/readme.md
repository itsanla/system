## setup kubernetes cluster

Salin dan jalankan perintah ini di terminal untuk mengaktifkan semua script:

```bash
#!/bin/bash
curl -o ssm-init.sh -L https://raw.githubusercontent.com/itsanla/system/refs/heads/main/aws/ssm-init.sh
chmod +x ssm-init.sh
./ssm-init.sh
```
```bash
curl -o ssm-run.sh -L https://raw.githubusercontent.com/itsanla/system/refs/heads/main/aws/ssm-run.sh
chmod +x ssm-run.sh
./ssm-run.sh
```
