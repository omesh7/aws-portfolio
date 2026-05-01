# Manage all secrets engines
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# List all secrets engines
path "sys/mounts" {
  capabilities = ["read"]
}

# Manage KV v2 secrets
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list", "patch"]
}

# Manage AWS secrets engine
path "aws/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage auth methods
path "sys/auth/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage policies
path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
