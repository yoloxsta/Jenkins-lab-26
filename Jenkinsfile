pipeline {
    agent any

    environment {
        compose_service_name = "react-jenkins-docker"
        workspace = "/home/jenkins/project/react-jenkins-docker"
    }

    stages {
        stage('Checkout Source') {
            steps {
                ws("${workspace}") {
                    checkout scm
                }
            }
        }

        stage('Docker Compose Build & Up') {
            steps {
                ws("${workspace}") {
                    sh "docker compose build --no-cache ${compose_service_name}"
                    sh "docker compose up --no-deps -d ${compose_service_name}"
                }
            }
        }
    }
}
