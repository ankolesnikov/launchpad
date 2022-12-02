#!/usr/bin/env sh

# Check if file exist terraform.tfvars
if [ ! -f ./terraform.tfvars ]; then
    echo "File terraform.tfvars not found!"
    echo "Please create one from terraform.tfvars.example!"
    exit 2
fi
terraform init
terraform apply -auto-approve
mv -i ./launchpad.yaml ./launchpad.$(date +"%Y-%m-%d_%H-%M").yaml
terraform output --raw mke_cluster > ./launchpad.yaml 
echo "Your launchpad.yaml sample is stored in your current directory" && ls ./launchpad.yaml
echo "Apply your configuration via launchpad apply"

exit 0