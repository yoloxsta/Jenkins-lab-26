pipeline {
    agent any

    environment {
        REMOTE_USER  = "ubuntu"
        REMOTE_HOST  = "103.112.61.209"
        REMOTE_DIR   = "/home/ubuntu/react-jenkins-docker"
        SERVICE_NAME = "react-jenkins-docker"
        SSH_CRED_ID  = "uat-ssh-key"  // Jenkins credential ID for SSH to remote server
        GIT_BRANCH   = "main"
        GIT_URL      = "git@github.com:yoloxsta/Jenkins-lab-26.git"
    }

    stages {

        stage('Checkout Source') {
            steps {
                // Checkout the Git repository using the configured credentials
                sshagent(credentials: ["github-repo-ssh"]) {
                    checkout([$class: 'GitSCM',
                        branches: [[name: "*/${GIT_BRANCH}"]],
                        userRemoteConfigs: [[
                            url: "${GIT_URL}",
                            credentialsId: "github-repo-ssh"
                        ]]
                    ])
                }
            }
        }

        stage('Deploy to Remote Server (Docker Compose)') {
            steps {
                sshagent(credentials: ["${SSH_CRED_ID}"]) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} << 'EOF'
                        set -e

                        # Disable BuildKit to avoid TLS issues during image build
                        export DOCKER_BUILDKIT=0

                        # Make sure the deployment directory exists
                        mkdir -p ${REMOTE_DIR}
                        cd ${REMOTE_DIR}

                        # Sync the current workspace to the remote server
                        rsync -avz --delete ./ ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}

                        # Build and run the service using Docker Compose
                        docker compose build --no-cache ${SERVICE_NAME}
                        docker compose up --no-deps -d ${SERVICE_NAME}

                        echo "Deployment complete!"
                    EOF
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully!"
        }
        failure {
            echo "Pipeline failed! Check logs for details."
        }
    }
}
