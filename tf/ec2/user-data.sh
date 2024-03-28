#!/bin/bash

# Update package lists
sudo apt update

# Install Python3 and pip3
sudo apt install -y python3 python3-pip net-tools

# Install Git
sudo apt install -y git

git clone https://github.com/bprathap104/flask-test-app-for-aws-services.git


curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Navigate into the cloned repository directory
mv flask-test-app-for-aws-services /home/ubuntu/
cd /home/ubuntu/flask-test-app-for-aws-services/app/

# Set up virtual environment
sudo apt install -y python3-venv
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
AURORA_ENDPOINT=$(aws ssm get-parameter --name "/demo/practice/aurora-endpoint" --query "Parameter.Value" --output text)
sed -i "s/DB_ENDPOINT/$AURORA_ENDPOINT/g" app.py

# Configure Flask application (replace 'app.py' with your actual entry point)
export FLASK_APP=app.py
export FLASK_ENV=production

# Run Flask application
nohup flask run --host=0.0.0.0 > /home/ubuntu/nohup.out 2>&1 &
