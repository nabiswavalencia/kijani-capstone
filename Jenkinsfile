pipeline {
  agent any

  parameters {
    string(name: 'BAD_TAG', defaultValue: '', description: 'Leave empty. Enter a tag that does not exist to test the rollback.')
  }

  environment {
    IMAGE_REPO = 'docker.io/lenceneema/kk-payments'
  }

  triggers {
    pollSCM('H/5 * * * *')
  }

  options {
    timeout(time: 30, unit: 'MINUTES')
  }

  stages {
    // Step 1. Install packages, run the linter and run the unit tests.
    stage('Test') {
      agent {
        docker {
          image 'node:22.23.3-alpine'
          args '-e HOME=/tmp'
          reuseNode true
        }
      }
      steps {
        dir('app') {
          sh 'npm ci && npm run lint && npm test'
        }
      }
    }

    // Step 2. Tag the image with the app version and commit, then push it to Docker Hub.
    stage('Build and Push') {
      steps {
        script {
          env.APP_VERSION = sh(script: "grep '\"version\"' app/package.json | cut -d '\"' -f4", returnStdout: true).trim()
          env.NEW_TAG = env.APP_VERSION + '-' + sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
          env.IMAGE_TAG = params.BAD_TAG ?: env.NEW_TAG
        }
        withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DH_USER', passwordVariable: 'DH_TOKEN')]) {
          sh '''
            docker build --build-arg APP_VERSION=$APP_VERSION -t $IMAGE_REPO:$NEW_TAG app
            echo "$DH_TOKEN" | docker login -u "$DH_USER" --password-stdin
            docker push $IMAGE_REPO:$NEW_TAG
          '''
        }
      }
    }

    // Step 3. Deploy to staging and wait for the pods to be ready.
    // Step 4. If they are not ready in 90 seconds, roll back and stop the pipeline.
    stage('Deploy to Staging') {
      steps {
        withCredentials([file(credentialsId: 'minikube-kubeconfig', variable: 'KUBECONFIG')]) {
          sh '''
            sed "s|IMAGE_PLACEHOLDER|$IMAGE_REPO:$IMAGE_TAG|" k8s/kk-payments-deployment.yaml > deploy.yaml
            kubectl apply -n kijani-staging -f deploy.yaml -f k8s/kk-payments-service.yaml
            if ! kubectl rollout status deployment/kk-payments -n kijani-staging --timeout=90s; then
              kubectl rollout undo deployment/kk-payments -n kijani-staging
              exit 1
            fi
          '''
        }
      }
    }

    // Step 5. Call /health in staging and check the version and environment.
    stage('Smoke Test') {
      steps {
        withCredentials([file(credentialsId: 'minikube-kubeconfig', variable: 'KUBECONFIG')]) {
          sh '''
            RESULT=$(kubectl exec -n kijani-staging deploy/kk-payments -- wget -qO- http://127.0.0.1:3001/health)
            echo "$RESULT"
            echo "$RESULT" | grep "\\"version\\":\\"$APP_VERSION\\""
            echo "$RESULT" | grep '"environment":"staging"'
          '''
        }
      }
    }

    // Step 6. Wait for a person to approve production and give a reason.
    stage('Approval') {
      steps {
        script {
          def reason = input(message: 'Deploy to production?', ok: 'Approve',
            parameters: [string(name: 'REASON', description: 'Why is this release safe?')])
          echo "Approved. Reason: ${reason}"
        }
      }
    }

    // Step 7. Deploy the same image to production.
    stage('Deploy to Production') {
      steps {
        withCredentials([file(credentialsId: 'minikube-kubeconfig', variable: 'KUBECONFIG')]) {
          sh '''
            kubectl apply -n default -f deploy.yaml -f k8s/kk-payments-service.yaml
            kubectl rollout status deployment/kk-payments -n default --timeout=90s
          '''
        }
      }
    }
  }

  post {
    success { echo "Released $IMAGE_TAG to production" }
    failure { echo 'Pipeline failed. Production was not changed.' }
    always { cleanWs() }
  }
}
