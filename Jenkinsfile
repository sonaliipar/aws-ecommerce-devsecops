pipeline {
  agent any
  options { timestamps(); disableConcurrentBuilds() }
  environment {
    AWS_REGION = credentials('aws-region')
    SONARQUBE_ENV = 'sonarqube'
    IMAGE_TAG = "${BUILD_NUMBER}"
  }
  stages {
    stage('Checkout') { steps { checkout scm } }
    stage('Build and test') {
      steps { dir('app') { sh 'mvn -B clean verify' } }
      post { always { junit allowEmptyResults: true, testResults: 'app/target/surefire-reports/*.xml' } }
    }
    stage('SonarQube SAST') {
      steps {
        withSonarQubeEnv('sonarqube') {
          dir('app') { sh 'mvn -B sonar:sonar -Dsonar.projectKey=ecommerce' }
        }
      }
    }
    stage('Sonar quality gate') {
      steps { timeout(time: 10, unit: 'MINUTES') { waitForQualityGate abortPipeline: true } }
    }
    stage('Veracode scan (optional)') {
      when { expression { return env.VERACODE_ENABLED == 'true' } }
      steps {
        withCredentials([string(credentialsId: 'veracode-api-id', variable: 'VERACODE_API_ID'),
                         string(credentialsId: 'veracode-api-key', variable: 'VERACODE_API_KEY')]) {
          sh 'echo "Configure Veracode Pipeline Scan or Upload and Scan here using approved CLI and policy."'
          sh 'test -n "$VERACODE_API_ID" && test -n "$VERACODE_API_KEY"'
        }
      }
    }
    stage('Build image') {
      steps { sh 'docker build -f docker/Dockerfile -t ecommerce:${IMAGE_TAG} .' }
    }
    stage('Trivy image scan') {
      steps { sh 'trivy image --exit-code 1 --severity HIGH,CRITICAL ecommerce:${IMAGE_TAG}' }
    }
    stage('Push to ECR') {
      when { branch 'main' }
      steps {
        sh '''
          test -n "$AWS_ACCOUNT_ID" && test -n "$ECR_REPOSITORY"
          aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
          docker tag ecommerce:${IMAGE_TAG} "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:${IMAGE_TAG}"
          docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:${IMAGE_TAG}"
        '''
      }
    }
    stage('Deploy to EKS') {
      when { branch 'main' }
      steps {
        sh '''
          aws eks update-kubeconfig --region "$AWS_REGION" --name "$EKS_CLUSTER_NAME"
          helm upgrade --install "$HELM_RELEASE" ./helm/ecommerce --namespace "$HELM_NAMESPACE" --create-namespace \
            --set image.repository="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY" \
            --set image.tag="${IMAGE_TAG}"
          kubectl rollout status deployment/"$HELM_RELEASE" -n "$HELM_NAMESPACE" --timeout=180s
        '''
      }
    }
  }
  post { always { sh 'docker image prune -f || true' } }
}
