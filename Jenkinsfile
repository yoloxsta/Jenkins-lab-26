pipeline {
    agent any

    environment {
        compose_service_name = "react-jenkins-docker"
    }

    stages {
        stage('Checkout Source') {
            steps {
                checkout scm
            }
        }

        stage('Docker Compose Build') {
            steps {
                sh "docker compose build --no-cache ${compose_service_name}"
            }
        }

        stage('Docker Compose Up') {
            steps {
                sh "docker compose up --no-deps -d ${compose_service_name}"
            }
        }
    }
}
