pipeline {
    agent any

    environment {
        REMOTE_USER  = "ubuntu"
        REMOTE_HOST  = "103.112.61.209"
        REMOTE_DIR   = "/home/ubuntu/react-jenkins-docker"
        SERVICE_NAME = "react-jenkins-docker"

        SSH_CRED_ID  = "uat-ssh-key"        // SSH key for remote server
        GIT_CRED_ID  = "github-repo-ssh"    // SSH key for GitHub
        GIT_BRANCH   = "main"
    }

    stages {

        stage('Checkout Source') {
            steps {
                sshagent(credentials: [env.GIT_CRED_ID]) {
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: "*/${GIT_BRANCH}"]],
                        userRemoteConfigs: [[
                            url: 'git@github.com:yoloxsta/Jenkins-lab-26.git',
                            credentialsId: env.GIT_CRED_ID
                        ]]
                    ])
                }
            }
        }

        stage('Deploy to Remote Server (Docker Compose)') {
            steps {
                sshagent(credentials: [env.SSH_CRED_ID]) {
                    sh """
set -e

# Sync project to remote server
rsync -az --delete \
  -e "ssh -o StrictHostKeyChecking=no" \
  ./ ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}

# SSH and deploy
ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} <<EOF
set -e
cd ${REMOTE_DIR}

docker compose build
docker compose up -d
EOF
"""
                }
            }
        }
    }

    post {
        success {
            echo "Deployment completed successfully!"
        }
        failure {
            echo "Pipeline failed. Check logs above."
        }
    }
}
