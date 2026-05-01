# Read access to secrets for the application
path "secret/data/app/*" {
  capabilities = ["read"]
}

# Allow list access to see what's there
path "secret/metadata/app/*" {
  capabilities = ["list"]
}
