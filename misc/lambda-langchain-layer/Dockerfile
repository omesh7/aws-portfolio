FROM public.ecr.aws/sam/build-python3.12

WORKDIR /var/task

COPY requirements.txt .

RUN python3 -m pip install --upgrade pip
RUN pip install virtualenv

# Install packages to the correct path for Lambda layers
RUN pip install -r requirements.txt -t python/lib/python3.12/site-packages/

# Create the zip file for Lambda layer
RUN zip -r python.zip python