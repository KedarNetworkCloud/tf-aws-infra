# tf-aws-infra

Purpose of this assignment is to learn to set up AWS infrastructure using terraform and to use
Github Actions to automate testing of terraform code.

We have set up 2 member accounts on AWS called "Dev" and "Demo" using our root AWS account. We have also enabled Multi Factor Authentication for both these accounts and the root account.

In both these member accounts we have Users called "DevRole" and "DemoRole" inside their respective UserGroups. For Assignment 3 these user groups have AmazonFullVPCAccess priviledge following "Least Access Priviledge Principle".

We have then configured these users to have Console access using their Secret Access Key and Access Key ID using the following command.

AWS Configure --profile DevRole

AWS Configure --profile DemoRole

AWS Configure list-profiles #To view all User profiles 

We will be using the following terraform commands to set up our AWS Networking infrastructure

1. Terraform init - Terraform scans the entire code to figure out which providers are being used, AWS for this assignment and then this command initializes it by downloading the respective provider plugins.

2. Terraform validate - This command is used to validate our terraform code making sure all configs are done properly and the terrafomr code is syntactically accurate.

3. Terraform plan - It shows a detailed preview of what Terraform will do when you apply a configuration, without actually making any changes.

4. Terraform apply - It applies the changes required to reach the desired state of the infrastructure as defined in the Terraform configuration files.

5. Terraform destroy - It destroys all the infrastructure set up by the Terraform by removing everything written in the configuration files.