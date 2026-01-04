def banner(msg) {
    echo "############################################"
    echo "### ${msg}"
    echo "############################################"
}

pipeline {
    agent any

    environment {
        REMOTE_USER  = "ubuntu"
        REMOTE_HOST  = "103.112.61.209"
        REMOTE_DIR   = "/home/ubuntu/react-jenkins-docker"

        IMAGE_NAME   = "yolomurphy/react-jenkins-docker"
        IMAGE_TAG    = "latest"

        SSH_CRED_ID       = "github-repo-ssh"
        GIT_CRED_ID       = "github-repo-ssh"
        DOCKERHUB_CRED_ID = "dockerhub-creds"

        GIT_BRANCH = "main"
    }

    stages {

        /* ===================== CHECKOUT ===================== */
        stage('Checkout Source') {
            steps {
                script {
                    banner("CHECKOUT STAGE IS STARTING")
                }

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

        /* ===================== UNIT TEST ===================== */
        stage('Unit Tests') {
            steps {
                script {
                    banner("UNIT TEST STAGE IS STARTING")
                }

                sh """
                npm install
                npm test -- --watchAll=false
                """
            }
        }

        /* ===================== BUILD ===================== */
        stage('Build Docker Image') {
            steps {
                script {
                    banner("DOCKER BUILD STAGE IS STARTING")
                }

                sh """
                docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                """
            }
        }

        /* ===================== SECURITY SCAN ===================== */
        stage('Image Scan (Trivy)') {
            steps {
                script {
                    banner("IMAGE SCANNING STAGE IS STARTING (TRIVY)")
                }

                sh """
                docker run --rm \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  aquasec/trivy:latest \
                  image \
                  --severity HIGH,CRITICAL \
                  --exit-code 1 \
                  ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        /* ===================== PUSH ===================== */
        stage('Push Image to Docker Hub') {
            steps {
                script {
                    banner("DOCKER PUSH STAGE IS STARTING")
                }

                withCredentials([
                    usernamePassword(
                        credentialsId: DOCKERHUB_CRED_ID,
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh """
                    echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    docker logout
                    """
                }
            }
        }

        /* ===================== DEPLOY ===================== */
        stage('Deploy to Remote Server') {
            steps {
                script {
                    banner("DEPLOYMENT STAGE IS STARTING")
                }

                sshagent(credentials: [env.SSH_CRED_ID]) {
                    sh """
set -e

# Copy docker-compose only
rsync -az \
  -e "ssh -o StrictHostKeyChecking=no" \
  docker-compose.yaml ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/

# SSH and deploy
ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} <<EOF
set -e
cd ${REMOTE_DIR}

docker compose pull
docker compose up -d
EOF
"""
                }
            }
        }

        /* ===================== HEALTH CHECK ===================== */
        stage('Post-Deploy Health Check') {
            steps {
                script {
                    banner("POST-DEPLOY HEALTH CHECK STAGE IS STARTING")
                }

                sh """
                sleep 10
                curl -f http://${REMOTE_HOST}:8091
                """
            }
        }
    }

    post {
        success {
            banner("PIPELINE COMPLETED SUCCESSFULLY 🚀")
        }
        failure {
            banner("PIPELINE FAILED — CHECK LOGS")
        }
    }
}
