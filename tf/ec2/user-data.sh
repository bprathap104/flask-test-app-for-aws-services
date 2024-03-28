#!/bin/bash

# Update package lists
sudo apt update

# Install Python3 and pip3
sudo apt install -y python3 python3-pip

# Install Git
sudo apt install -y git

git clone https://github.com/bprathap104/flask-test-app-for-aws-services.git

# Navigate into the cloned repository directory
cd flask-test-app-for-aws-services/app/

# Set up virtual environment
sudo apt install -y python3-venv
# python3 -m venv venv
# source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Configure Flask application (replace 'app.py' with your actual entry point)
export FLASK_APP=app.py
export FLASK_ENV=production

# Run Flask application
nohup flask run --host=0.0.0.0 > /dev/null 2>&1 &
