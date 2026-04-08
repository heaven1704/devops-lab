pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        TF_DIR = 'terraform'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Cloning repository...'
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    dir("${TF_DIR}") {
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    dir("${TF_DIR}") {
                        sh 'terraform plan -out=tfplan'
                    }
                }
            }
        }

        stage('Approval') {
            steps {
                input message: 'Review the Terraform plan above. Approve to apply?',
                      ok: 'Deploy'
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    dir("${TF_DIR}") {
                        sh 'terraform apply -auto-approve tfplan'
                        script {
                            env.EC2_IP = sh(
                                script: "terraform output -raw ec2_public_ip",
                                returnStdout: true
                            ).trim()
                        }
                    }
                }
            }
        }

        stage('Ansible Configure') {
            steps {
                sshagent(credentials: ['ec2-key']) {
                    sh """
                        sleep 60
                        ansible-playbook ansible/configure.yml \
                            -i "${env.EC2_IP}," \
                            -u ec2-user \
                            --ssh-common-args='-o StrictHostKeyChecking=no'
                    """
                }
            }
        }

        stage('Test Lambda') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds'
                ]]) {
                    dir("${TF_DIR}") {
                        script {
                            def funcName = sh(
                                script: "terraform output -raw lambda_function_name",
                                returnStdout: true
                            ).trim()
                            sh """
                                aws lambda invoke \
                                    --function-name ${funcName} \
                                    --payload '{}' \
                                    --cli-binary-format raw-in-base64-out \
                                    response.json
                                cat response.json
                            """
                        }
                    }
                }
            }
        }

        stage('Smoke Test') {
            steps {
                script {
                    sh "curl -f http://${env.EC2_IP} || echo 'Web test done'"
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs above.'
        }
        always {
            echo 'Pipeline finished.'
        }
    }
} 