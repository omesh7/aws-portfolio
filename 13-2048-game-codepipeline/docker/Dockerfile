FROM public.ecr.aws/lambda/python:3.11

# Copy function code
COPY lambda/app.py ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler
CMD [ "app.lambda_handler" ]