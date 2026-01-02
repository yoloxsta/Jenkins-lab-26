pipeline {
    agent any

    environment {
        REMOTE_USER  = "ubuntu"
        REMOTE_HOST  = "43.204.77.55"
        REMOTE_DIR   = "/home/ubuntu/react-jenkins-docker"
        SERVICE_NAME = "react-jenkins-docker"
        SSH_CRED_ID  = "uat-ssh-key"
        GIT_BRANCH   = "main"
    }

    stages {

        stage('Checkout Source') {
            steps {
                checkout scm
            }
        }

        stage('Deploy to Remote Server (Docker Compose)') {
            steps {
                sshagent(credentials: ["${SSH_CRED_ID}"]) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} << 'EOF'
                        set -e

                        mkdir -p ${REMOTE_DIR}
                        cd ${REMOTE_DIR}

                        if [ ! -d .git ]; then
                            git clone ${GIT_URL} .
                        else
                            git fetch origin
                            git checkout ${GIT_BRANCH}
                            git pull origin ${GIT_BRANCH}
                        fi

                        docker compose build --no-cache ${SERVICE_NAME}
                        docker compose up --no-deps -d ${SERVICE_NAME}
                    EOF
                    """
                }
            }
        }
    }
}
