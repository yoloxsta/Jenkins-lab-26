def banner(msg) {
    echo "############################################"
    echo "### ${msg}"
    echo "############################################"
}

pipeline {
    agent any

    environment {
        REMOTE_USER   = "ubuntu"
        REMOTE_HOST   = "103.112.61.209"
        REMOTE_DIR    = "/home/ubuntu/react-jenkins-docker"

        IMAGE_NAME    = "yolomurphy/react-jenkins-docker"
        IMAGE_TAG     = "latest"

        SSH_CRED_ID        = "github-repo-ssh"
        GIT_CRED_ID        = "github-repo-ssh"
        DOCKERHUB_CRED_ID  = "dockerhub-creds"

        GIT_BRANCH = "main"
    }

    stages {

        /* ================= CHECKOUT ================= */
        stage('Checkout Source') {
            steps {
                script { banner("Checkout stage is starting") }

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

        /* ================= SEMGREP ================= */
        stage('Code Scan (Semgrep – Non Blocking)') {
            steps {
                script { banner("Code scanning stage is starting (Semgrep)") }

                sh '''
                mkdir -p reports

                docker run --rm \
                  -v "$PWD:/src" \
                  returntocorp/semgrep \
                  semgrep scan \
                  --config=p/ci \
                  --exclude=Dockerfile \
                  --exclude=docker-compose.yaml \
                  --json \
                  --output /src/reports/semgrep-report.json \
                  /src || true
                '''
            }

            post {
                always {
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'reports',
                        reportFiles: 'semgrep-report.json',
                        reportName: 'Semgrep Security Report'
                    ])
                }
            }
        }

        /* ================= BUILD ================= */
        stage('Build Docker Image') {
            steps {
                script { banner("Docker build stage is starting") }

                sh """
                docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                """
            }
        }

        /* ================= TRIVY ================= */
        stage('Image Scan (Trivy)') {
            steps {
                script { banner("Image scanning stage is starting (Trivy)") }

                sh """
                docker run --rm \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  aquasec/trivy:latest \
                  image \
                  --severity HIGH,CRITICAL \
                  --exit-code 0 \
                  ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        /* ================= PUSH ================= */
        stage('Push Image to Docker Hub') {
            steps {
                script { banner("Docker push stage is starting") }

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

        /* ================= DEPLOY ================= */
        stage('Deploy on Remote Server') {
            steps {
                script { banner("Remote deployment stage is starting") }

                sshagent(credentials: [env.SSH_CRED_ID]) {
                    sh """
                    rsync -az \
                      -e "ssh -o StrictHostKeyChecking=no" \
                      docker-compose.yaml ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/

                    ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} <<EOF
                    cd ${REMOTE_DIR}
                    docker compose pull
                    docker compose up -d
                    EOF
                    """
                }
            }
        }
    }

    post {
        success {
            banner("PIPELINE COMPLETED SUCCESSFULLY 🚀")
        }
        failure {
            banner("PIPELINE FAILED — CHECK LOGS ❌")
        }
    }
}
