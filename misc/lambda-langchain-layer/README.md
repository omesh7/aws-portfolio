# AWS Lambda Layer Builder for LangChain

This project creates an AWS Lambda Layer containing LangChain and related dependencies. Lambda Layers let you include libraries in your Lambda functions without bundling them with your function code.

![AWS Lambda Layers](https://img.shields.io/badge/AWS-Lambda%20Layers-orange)
![Python](https://img.shields.io/badge/Python-3.12-blue)
![LangChain](https://img.shields.io/badge/LangChain-Latest-green)

## 📋 Overview

This project automates building a Lambda Layer for LangChain using Docker to ensure compatibility with the Lambda runtime environment. The generated layer can be directly uploaded to AWS Lambda.

## 🔧 How It Works

The project uses Docker to:

1. Create a Lambda-compatible environment
2. Install Python packages into the correct directory structure
3. Package them into a ZIP file ready for Lambda

## 📁 Project Structure

```txt
.
├── Dockerfile           # Defines the Lambda layer build process
├── requirements.txt     # Python dependencies for the layer
├── create_layer.sh      # Script to build and extract the layer
└── readme.md            # Documentation
```

## 📋 Requirements

- Docker installed and running
- AWS CLI (for uploading the layer) - Optional
- Basic shell environment

## 🚀 Quick Start

1. **Clone the repository:**

   ```bash
   git clone https://github.com/derevya/aws-langchain-lambda-layer.git
   cd aws-langchain-lambda-layer
   ```

2. **Customize dependencies (optional):**
   Edit `requirements.txt` to add or remove packages as needed.

3. **Run the build script:**

   ```bash
   chmod +x create_layer.sh
   ./create_layer.sh
   ```

4. **Upload to AWS Lambda:**

   ```bash
   aws lambda publish-layer-version \
       --layer-name langchain-layer \
       --description "LangChain dependencies" \
       --zip-file fileb://langchain_lambda_layer.zip \
       --compatible-runtimes python3.12
   ```

   **Alternative: Upload via AWS Web Console:**

   1. Upload the ZIP file to an S3 bucket:

      ```bash
      aws s3 cp langchain_lambda_layer.zip s3://your-bucket-name/
      ```

   2. In the AWS Lambda Console:
      - Go to "Layers" in the left navigation
      - Click "Create layer"
      - Enter a name for your layer (e.g., "langchain-layer")
      - Under "Code entry type", select "Amazon S3 link"
      - Paste the S3 URL of your ZIP file (max 50MB allowed)
      - Select compatible runtime(s) (e.g., Python 3.12)
      - Click "Create" to publish the layer

## 🔍 AWS Lambda Layer Structure

Lambda layers follow a specific directory structure:

```txt
python/
└── lib/
    └── python3.12/
        └── site-packages/
            ├── langchain_community/
            ├── langchain_core/
            └── ...
```

This structure enables AWS Lambda to automatically include these packages in your function's Python path.

## ⚙️ Customization

### Adding Custom Packages

To add custom dependencies, simply edit the `requirements.txt` file, adding one package per line:

```txt
# Add packages like this:
package-name==version
another-package>=minimum.version
```

### Using a Different Python Version

To target a different Python runtime:

1. Change the base image in the Dockerfile
2. Update the installation path to match your Python version

## 🔧 Troubleshooting

- **Layer size limits**: AWS Lambda layers have a max unzipped size of 250 MB
- **Dependencies compatibility**: Some packages with native code might require additional configuration
- **Permission errors**: Ensure the Docker daemon has sufficient permissions to build and run containers
- **Memory limitations**: When using LangChain with Lambda, you'll likely need to increase the function's memory from the default 128MB to at least 1024MB for better performance

## 📄 License

[MIT License](LICENSE)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
