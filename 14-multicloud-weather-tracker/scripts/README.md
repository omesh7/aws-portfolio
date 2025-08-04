# Multi-Cloud Weather Tracker Scripts

## Linux Scripts (`linux/`)

Make scripts executable first:
```bash
chmod +x linux/*.sh
```

### Deploy
```bash
./linux/deploy.sh
```

### Check Status
```bash
./linux/status.sh
```

### Test Failover
```bash
./linux/test-failover.sh
```

### Destroy
```bash
./linux/destroy.sh
```

## Windows Scripts (`windows/`)

### Deploy
```cmd
windows\deploy.bat
```

### Check Status
```cmd
windows\status.bat
```

### Test Failover
```cmd
windows\test-failover.bat
```

### Destroy
```cmd
windows\destroy.bat
```

## Prerequisites

- Terraform installed
- AWS CLI configured
- OpenWeather API key set in terraform.tfvars