# Set base path
$basePath = "app"
$handlerPath = "$basePath/handlers"

# Create folders
New-Item -ItemType Directory -Force -Path $basePath, $handlerPath

# Handler files
$handlerFiles = @(
    "add_conversation.py",
    "delete_document.py",
    "generate_embeddings.py",
    "generate_presigned_url.py",
    "generate_response.py",
    "get_all_documents.py",
    "get_document.py",
    "upload_trigger.py"
)

# Create handler files
foreach ($file in $handlerFiles) {
    New-Item -ItemType File -Force -Path "$handlerPath/$file"
}

# Create core app files
New-Item -ItemType File -Force -Path "$basePath/main.py"
New-Item -ItemType File -Force -Path "$basePath/routes.py"
New-Item -ItemType File -Force -Path "$basePath/utils.py"

# Optional: create empty requirements.txt and Dockerfile
New-Item -ItemType File -Force -Path "requirements.txt"
New-Item -ItemType File -Force -Path "Dockerfile"

Write-Host "✅ Project structure created!"
