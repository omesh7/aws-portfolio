# N8N Two-Stage Deployment

This deployment requires two stages due to Terraform count dependencies in the module.

## Stage 1: Initial Deployment

1. **Deploy without certificate**:
   ```bash
   terraform apply
   ```
   This creates the infrastructure with HTTP-only access.

2. **Wait for certificate validation** (usually 2-5 minutes):
   ```bash
   # Check certificate status
   aws acm describe-certificate --certificate-arn $(terraform output -raw certificate_arn)
   ```

## Stage 2: Enable HTTPS

1. **Uncomment certificate line** in `main.tf`:
   ```hcl
   certificate_arn = aws_acm_certificate_validation.n8n_cert_validation.certificate_arn
   ```

2. **Apply again**:
   ```bash
   terraform apply
   ```

## Alternative: Single Command

Use targeted apply to avoid the count issue:

```bash
# Deploy certificate resources first
terraform apply -target=aws_acm_certificate_validation.n8n_cert_validation

# Then deploy everything
terraform apply
```

## Access

- **HTTP**: `http://<load-balancer-dns>`
- **HTTPS**: `https://n8n.yourdomain.com` (after stage 2)