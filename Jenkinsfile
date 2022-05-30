pipeline {

  agent any

    parameters {
      
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
        booleanParam(name: 'destroy', defaultValue: false, description: 'Destroy Terraform build?')

    }

  environment {
      TF_IN_AUTOMATION = 'true'
      AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')
      AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
  }

  stages {

    stage('Init') {
        when {
                not {
                    equals expected: true, actual: params.destroy
                }
            }
        steps {
            sh 'ls'
            sh 'cat $BRANCH_NAME.tfvars'
            sh 'terraform init -no-color'
        }
    }

    stage('Plan') {
        when {
                not {
                    equals expected: true, actual: params.destroy
                }
            }
        steps {
            sh 'terraform plan -no-color -var-file="$BRANCH_NAME.tfvars"'
        }
    }

    stage('Validate Apply') {
      when {
        beforeInput true
        not {
                equals expected: true, actual: params.autoApprove
            }
        not {
                equals expected: true, actual: params.destroy
            }
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
        when {
                not {
                    equals expected: true, actual: params.destroy
                }
            }
        steps {
            sh 'terraform apply -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
        }
    }

    stage('Ansible') {
        when {
                not {
                    equals expected: true, actual: params.destroy
                }
            }
        steps {
            ansiblePlaybook(credentialsId: 'ec2-ssh-key', inventory: 'ansible/aws_ec2.yml', playbook: 'ansible/web-ec2.yml')
        }
    }

 

    stage('Destroy') {
        when {
                equals expected: true, actual: params.destroy
            }
        steps {
            sh 'terraform init -reconfigure'
            sh 'terraform destroy -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
        }
    }
  }
  
}
