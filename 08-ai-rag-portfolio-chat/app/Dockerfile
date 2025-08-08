FROM public.ecr.aws/lambda/python:3.12

# Set working directory to Lambda's task root
WORKDIR ${LAMBDA_TASK_ROOT}

# Copy all files inside ./app to Lambda task root
COPY . .

# Install Python dependencies
RUN pip install -r requirements.txt

# Set the handler (adjust if your main file or function name changes)
CMD [ "main.lambda_handler" ]
