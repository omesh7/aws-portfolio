import os
import hvac
from flask import Flask, jsonify

app = Flask(__name__)

# Vault Configuration
VAULT_ADDR = os.getenv("VAULT_ADDR", "https://vault.example.com")
ROLE_ID = os.getenv("ROLE_ID")
SECRET_ID = os.getenv("SECRET_ID")

def get_vault_client():
    client = hvac.Client(url=VAULT_ADDR)
    
    # Authenticate via AppRole
    login_response = client.auth.approle.login(
        role_id=ROLE_ID,
        secret_id=SECRET_ID,
    )
    
    return client

@app.route("/")
def index():
    return jsonify({"status": "healthy", "service": "sample-app-vault-demo"})

@app.route("/secret")
def get_secret():
    try:
        client = get_vault_client()
        
        # Fetch secret from KV v2
        read_response = client.secrets.kv.v2.read_secret_version(
            path="app/config",
            mount_point="secret"
        )
        
        db_password = read_response['data']['data']['db_password']
        
        # Redact secret in response for demo safety, or show first/last chars
        redacted_password = db_password[0] + "*" * (len(db_password) - 2) + db_password[-1]
        
        return jsonify({
            "status": "success",
            "message": "Fetched secret from Vault!",
            "db_password_redacted": redacted_password
        })
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
