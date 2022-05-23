pipeline {

  agent any

  environment {
    AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
    AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
  }

  stages {

    stage('Init') {
        steps {
            sh 'ls'
            sh 'cat $BRANCH_NAME.tfvars'
            sh 'terraform init -no-color'
        }
    }

    stage('Plan') {
        steps {
            sh 'terraform plan -no-color -var-file="$BRANCH_NAME.tfvars"'
        }
    }

    stage('Validate Apply') {
        when {
            beforeInput true
            branch "dev"
        }
        input {
            message "Do you want to apply this plan?"
            ok "Apply plan"
        }
        steps {
            echo 'Apply Accepted'
        }
    }

    stage('Apply') {
        steps {
            sh 'terraform apply -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
        }
    }

    stage('Ansible') {
        steps {
            ansiblePlaybook(credentialsId: 'ec2-ssh-key', inventory: 'ansible/aws_ec2.yml', playbook: 'ansible/web-ec2.yml')
        }
    }

    stage('Validate Destroy') {
        input {
            message "Do you want to destroy?"
            ok "Destroy"
            }
        steps {
            echo 'Destroy Approved'
        }
    }

    stage('Destroy') {
        steps {
            sh 'terraform destroy -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
        }
    }
  }
  
}