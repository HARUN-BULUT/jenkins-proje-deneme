pipeline {
    agent any

    environment {
        // REPO_URL = 'https://github.com/HARUN-BULUT/jenkins-proje-deneme.git'
        ECR_REPO_NAME = '904602740498.dkr.ecr.us-east-1.amazonaws.com'  // my-ecr-repo
        AWS_REGION = 'us-east-1'
    }

    stages {
    //     stage('Clone Repository') {
    //         steps {
    //             git url: "${REPO_URL}"
    //         }
    //     }

        stage('Create ECR Repository') {
            steps {
                script {
                    // AWS CLI komutu çalıştırma
                    sh '''
                    aws ecr create-repository --repository-name postgresql --region $AWS_REGION
                    aws ecr create-repository --repository-name nodejs --region $AWS_REGION
                    aws ecr create-repository --repository-name react --region $AWS_REGION
                    '''
                }
            }
        }


        stage('Build and Push Docker Images') {
            steps {
                dir('student_files') {
            script {
                sh 'docker build -t ${ECR_REPO_NAME}/postgresql:latest -f dockerfile-postgresql .'
            }
        }
                dir('student_files') {
            script {
                sh 'docker build -t ${ECR_REPO_NAME}/nodejs:latest -f dockerfile-nodejs .'
            }
        }
                dir('student_files') {
            script {
                sh 'docker build -t ${ECR_REPO_NAME}/react:latest -f dockerfile-react .'
            }
        }
            script {
                sh 'aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO_NAME}'
                sh 'docker push ${ECR_REPO_NAME}/postgresql:latest'
                sh 'docker push ${ECR_REPO_NAME}/nodejs:latest'
                sh 'docker push ${ECR_REPO_NAME}/react:latest'
        }
    }
}




        // stage('Build and Push Docker Images') {
        //     steps {
        //         script {
        //             sh 'docker build -t ${ECR_REPO_NAME}/postgresql:latest -f dockerfile-postgresql ./student_files/postgresql/'
        //             sh 'docker build -t ${ECR_REPO_NAME}/nodejs:latest -f dockerfile-nodejs ./student_files/nodejs/'
        //             sh 'docker build -t ${ECR_REPO_NAME}/react:latest -f dockerfile-react ./student_files/react/'
                    
        //             sh 'aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO_NAME}'
                    
        //             sh 'docker push ${ECR_REPO_NAME}/postgresql:latest'
        //             sh 'docker push ${ECR_REPO_NAME}/nodejs:latest'
        //             sh 'docker push ${ECR_REPO_NAME}/react:latest'
        //         }
        //     }
        // }


        stage('Terraform Apply') {
            steps {
                script {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('wait') {
            steps {
                timeout(time:5, unit:'DAYS'){
                    input message:'Approve PRODUCTION Deployment?'
                }
            }
        }

        stage('Deploy with Ansible') {
            steps {
                script {
                    sh 'ansible-playbook -i inventory_aws_ec2.yml docker.yml'
                    sh 'ansible-playbook -i inventory_aws_ec2.yml postgresql.yml --extra-vars "ecr_repo_name=${env.ECR_REPO_NAME}/postgresql"'
                    sh 'ansible-playbook -i inventory_aws_ec2.yml nodejs.yml --extra-vars "ecr_repo_name=${env.ECR_REPO_NAME}/nodejs"'
                    sh 'ansible-playbook -i inventory_aws_ec2.yml react.yml --extra-vars "ecr_repo_name=${env.ECR_REPO_NAME}/react"'
                }
            }
        }
    }

    post {
        failure {
            script {
                sh 'terraform destroy -auto-approve'
            }
        }
    }

    
}
