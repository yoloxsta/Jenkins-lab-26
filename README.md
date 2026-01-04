# Getting Started with Create React App

This project was bootstrapped with [Create React App](https://github.com/facebook/create-react-app).

## Available Scripts

In the project directory, you can run:

### `npm start`

Runs the app in the development mode.\
Open [http://localhost:3000](http://localhost:3000) to view it in your browser.

The page will reload when you make changes.\
You may also see any lint errors in the console.

### `npm test`

Launches the test runner in the interactive watch mode.\
See the section about [running tests](https://facebook.github.io/create-react-app/docs/running-tests) for more information.

### `npm run build`

Builds the app for production to the `build` folder.\
It correctly bundles React in production mode and optimizes the build for the best performance.

The build is minified and the filenames include the hashes.\
Your app is ready to be deployed!

See the section about [deployment](https://facebook.github.io/create-react-app/docs/deployment) for more information.

### `npm run eject`

**Note: this is a one-way operation. Once you `eject`, you can't go back!**

If you aren't satisfied with the build tool and configuration choices, you can `eject` at any time. This command will remove the single build dependency from your project.

Instead, it will copy all the configuration files and the transitive dependencies (webpack, Babel, ESLint, etc) right into your project so you have full control over them. All of the commands except `eject` will still work, but they will point to the copied scripts so you can tweak them. At this point you're on your own.

You don't have to ever use `eject`. The curated feature set is suitable for small and middle deployments, and you shouldn't feel obligated to use this feature. However we understand that this tool wouldn't be useful if you couldn't customize it when you are ready for it.

## Learn More

You can learn more in the [Create React App documentation](https://facebook.github.io/create-react-app/docs/getting-started).

To learn React, check out the [React documentation](https://reactjs.org/).

### Code Splitting

This section has moved here: [https://facebook.github.io/create-react-app/docs/code-splitting](https://facebook.github.io/create-react-app/docs/code-splitting)

### Analyzing the Bundle Size

This section has moved here: [https://facebook.github.io/create-react-app/docs/analyzing-the-bundle-size](https://facebook.github.io/create-react-app/docs/analyzing-the-bundle-size)

### Making a Progressive Web App

This section has moved here: [https://facebook.github.io/create-react-app/docs/making-a-progressive-web-app](https://facebook.github.io/create-react-app/docs/making-a-progressive-web-app)

### Advanced Configuration

This section has moved here: [https://facebook.github.io/create-react-app/docs/advanced-configuration](https://facebook.github.io/create-react-app/docs/advanced-configuration)

### Deployment

This section has moved here: [https://facebook.github.io/create-react-app/docs/deployment](https://facebook.github.io/create-react-app/docs/deployment)

### `npm run build` fails to minify

This section has moved here: [https://facebook.github.io/create-react-app/docs/troubleshooting#npm-run-build-fails-to-minify](https://facebook.github.io/create-react-app/docs/troubleshooting#npm-run-build-fails-to-minify)

## jenkinsfile (git clone and compose up)
```
pipeline {
    agent any

    environment {
        REMOTE_USER  = "ubuntu"
        REMOTE_HOST  = "103.112.61.209"
        REMOTE_DIR   = "/home/ubuntu/react-jenkins-docker"
        SERVICE_NAME = "react-jenkins-docker"

        SSH_CRED_ID  = "github-repo-ssh"        // SSH key for remote server
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

```

## Nginx conf for Jenkins
```
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name jenkinslab.sta.com;

    # Redirect all HTTP requests to HTTPS
    return 301 https://$host$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name jenkinslab.sta.com;

    # SSL configuration (managed by Certbot)
    ssl_certificate /etc/letsencrypt/live/jenkinslab.sta.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/jenkinslab.sta.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Main Jenkins location
    location / {
        proxy_pass http://127.0.0.1:8080;

        # Standard headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Port $server_port;

        # Required for Jenkins WebSocket (Blue Ocean, pipeline logs)
        proxy_http_version 1.1;
        proxy_request_buffering off;
        proxy_buffering off;
        proxy_read_timeout 86400;

        # Optional: large file uploads
        client_max_body_size 500M;
    }

    # Serve static files efficiently
    location ~ ^/static/ {
        proxy_pass http://127.0.0.1:8080;
    }

    # Optional: deny access to sensitive directories
    location ~ /(WEB-INF|META-INF|\.git) {
        deny all;
    }
}

```
## Jenkinsfile (build,push to Dockerhub,pull and deploy)
```
pipeline {
    agent any

    environment {
        REMOTE_USER   = "ubuntu"
        REMOTE_HOST   = "103.112.61.209"
        REMOTE_DIR    = "/home/ubuntu/react-jenkins-docker"

        IMAGE_NAME    = "yolomurphy/react-jenkins-docker"
        IMAGE_TAG     = "latest"

        SSH_CRED_ID   = "github-repo-ssh"
        GIT_CRED_ID   = "github-repo-ssh"
        DOCKERHUB_CRED_ID = "dockerhub-creds"

        GIT_BRANCH    = "main"
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

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                """
            }
        }

        stage('Push Image to Docker Hub') {
            steps {
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
                sshagent(credentials: [env.SSH_CRED_ID]) {
                    sh """
set -e

# Sync docker-compose only (no source code needed)
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
    }

    post {
        success {
            echo "🚀 Deployment completed successfully!"
        }
        failure {
            echo "Pipeline failed. Check logs above."
        }
    }
}

```
## Jenkinsfile update (trivy)
```
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
                script {
                    banner("Checkout stage is starting")
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

        stage('Build Docker Image') {
            steps {
                script {
                    banner("Docker build stage is starting")
                }

                sh """
                docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                """
            }
        }

        stage('Image Scanning (Trivy)') {
            steps {
                script {
                    banner("Image scanning stage is starting (Trivy)")
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

        stage('Push Image to Docker Hub') {
            steps {
                script {
                    banner("Docker push stage is starting")
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

        stage('Deploy on Remote Server') {
            steps {
                script {
                    banner("Remote deployment stage is starting")
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

```
