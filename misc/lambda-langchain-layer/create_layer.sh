#!/bin/bash
set -e  # Exit on error

# Configuration
layer_name=langchain_lambda_layer
container_name=docker_lambda_container
docker_image=aws_lambda_image

echo "Building Docker image..."
docker build . -t $docker_image

echo "Running container to generate Lambda layer..."
docker run -td --name=$container_name $docker_image

echo "Copying Lambda layer zip from container..."
docker cp $container_name:/var/task/python.zip ./${layer_name}.zip

echo "Cleaning up container..."
docker stop $container_name
docker rm $container_name

echo "✅ Lambda layer created: ${layer_name}.zip"
echo "Layer size: $(du -h ${layer_name}.zip | cut -f1)"
