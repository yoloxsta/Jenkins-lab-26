pipeline {
    agent any

    environment {
        REMOTE_USER  = "ubuntu"
        REMOTE_HOST  = "103.112.61.209"
        REMOTE_DIR   = "/home/ubuntu/react-jenkins-docker"
        SERVICE_NAME = "react-jenkins-docker"
        SSH_CRED_ID  = "uat-ssh-key"
        GIT_BRANCH   = "main"
        GIT_URL      = "git@github.com:yoloxsta/Jenkins-lab-26.git"
    }

    stages {

        stage('Checkout Source') {
            steps {
                // Checkout the Jenkinsfile repo itself
                checkout scm
            }
        }

        stage('Deploy to Remote Server (Docker Compose)') {
            steps {
                sshagent(credentials: ["${SSH_CRED_ID}"]) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} << 'ENDSSH'
                        set -e

                        # Ensure remote directory exists
                        mkdir -p ${REMOTE_DIR}
                        cd ${REMOTE_DIR}

                        # Ensure GitHub host key is known to avoid host verification issues
                        mkdir -p ~/.ssh
                        touch ~/.ssh/known_hosts
                        chmod 600 ~/.ssh/known_hosts
                        ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null || true

                        # Clone or update repo
                        if [ ! -d .git ]; then
                            git clone -b ${GIT_BRANCH} ${GIT_URL} .
                        else
                            git fetch origin
                            git checkout ${GIT_BRANCH}
                            git pull origin ${GIT_BRANCH}
                        fi

                        # Build and deploy service using Docker Compose
                        docker compose build --no-cache ${SERVICE_NAME}
                        docker compose up --no-deps -d ${SERVICE_NAME}
                    ENDSSH
                    """
                }
            }
        }
    }
}
