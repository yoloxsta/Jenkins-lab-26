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

        stage('Code Scan (Semgrep - Non Blocking)') {
            steps {
                script {
                    banner("Code scanning stage is starting (Semgrep)")
                }

                sh '''
                mkdir -p reports

                # Run Semgrep and output JSON
                docker run --rm \
                  -v "$PWD:/src" \
                  returntocorp/semgrep \
                  semgrep scan \
                  --config=p/ci \
                  --exclude=Dockerfile \
                  --exclude=docker-compose.yaml \
                  --json /src/reports/semgrep-report.json || true

                # Convert JSON to HTML using Semgrep CLI
                docker run --rm \
                  -v "$PWD:/src" \
                  returntocorp/semgrep \
                  semgrep --json-to-html /src/reports/semgrep-report.json -o /src/reports/semgrep-report.html
                '''
            }

            post {
                always {
                    // Archive the HTML report
                    archiveArtifacts artifacts: 'reports/semgrep-report.html', allowEmptyArchive: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script { banner("Docker build stage is starting") }
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Image Scanning (Trivy)') {
            steps {
                script { banner("Image scanning stage is starting (Trivy)") }
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

        stage('Deploy on Remote Server') {
            steps {
                script { banner("Remote deployment stage is starting") }
                sshagent(credentials: [env.SSH_CRED_ID]) {
                    sh """
set -e
rsync -az -e "ssh -o StrictHostKeyChecking=no" docker-compose.yaml ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/
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
    }

    post {
        always {
            archiveArtifacts artifacts: 'reports/semgrep-report.html', fingerprint: true
        }
        success {
            banner("PIPELINE COMPLETED SUCCESSFULLY 🚀")
        }
        failure {
            banner("PIPELINE FAILED — CHECK LOGS")
        }
    }
}
