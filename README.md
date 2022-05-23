# jenkins-terraform-ansible-aws

This project creates the infrastructure in aws with terraform. It creates vpc, subnets, Internet-gateway, autoscaling group and ALB.

Then ansible playbooks configure ec2 instances by installing apache web server and cloning a repo with basic web page. 

The project also contains Jenkinsfile, so it is possible to create a pipeline which will automate the process of infrastructure 
provisioning and deploying web servers.
 
