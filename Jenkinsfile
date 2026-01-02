pipeline {
    agent any

    environment {
        REMOTE_USER  = "ubuntu"
        REMOTE_HOST  = "103.112.61.209"
        REMOTE_DIR   = "/home/ubuntu/react-jenkins-docker"
        SERVICE_NAME = "react-jenkins-docker"
        SSH_CRED_ID  = "uat-ssh-key"        // Jenkins credential for remote host
        GIT_CRED_ID  = "github-repo-ssh"   // Jenkins credential for GitHub
        GIT_BRANCH   = "main"
    }

    stages {

        stage('Checkout Source') {
            steps {
                // Checkout GitHub repo using Jenkins credential
                sshagent(credentials: ["${GIT_CRED_ID}"]) {
                    checkout([$class: 'GitSCM', 
                              branches: [[name: "${GIT_BRANCH}"]],
                              userRemoteConfigs: [[url: 'git@github.com:yoloxsta/Jenkins-lab-26.git', credentialsId: "${GIT_CRED_ID}"]]
                    ])
                }
            }
        }

        stage('Deploy to Remote Server (Docker Compose)') {
            steps {
                sshagent(credentials: ["${SSH_CRED_ID}"]) {
                    sh """
                    # Copy workspace from Jenkins to remote server
                    rsync -avz --delete -e "ssh -o StrictHostKeyChecking=no" ./ ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}

                    # SSH into remote server and deploy
                    ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} << 'ENDSSH'
                        set -e
                        cd ${REMOTE_DIR}

                        # Build and run the Docker Compose service
                        docker compose build --no-cache ${SERVICE_NAME}
                        docker compose up --no-deps -d ${SERVICE_NAME}
                    ENDSSH
                    """
                }
            }
        }
    }

    post {
        failure {
            echo "Pipeline failed! Check the logs above for details."
        }
        success {
            echo "Deployment completed successfully!"
        }
    }
}
