pipeline {
  agent {
    node {
      label 'nodejs'
    }
  }

  environment {
    APP_NAME = 'bob-web-vue3'
    APP_VER = '6.1.0-RELEASE'
    GITLAB_URL = 'https://gitee.com/elf_express/bob-web-monorepo-framework.git'
    GITLAB_CREDENTIAL_ID = 'gitlab-id'
    REGISTRY = '192.168.11.254:8091'
    REGISTRY_CREDENTIAL_ID = 'harbor-id'
    REGISTRY_NAMESPACE = 'bobsoft'
    KUBECONFIG_CREDENTIAL_ID = 'kubeconfig-id'
    BRANCH_NAME = 'k8s'
    REMARKS = 'bob-web-vue3 deploy pipeline'
  }

  stages {
    stage('Checkout SCM') {
      steps {
        git(
          credentialsId: "$GITLAB_CREDENTIAL_ID",
          url: "$GITLAB_URL",
          branch: "$BRANCH_NAME",
          changelog: true,
          poll: false
        )
      }
    }

    stage('Main Quality Gate') {
      steps {
        container('nodejs') {
          sh '''
            set -e
            corepack enable
            pnpm --version
            pnpm install --frozen-lockfile
            pnpm run ci:main:e2e:prepare
            pnpm run ci:main:gate:full
          '''
        }
      }
    }

    stage('Build & Push Images') {
      agent none
      steps {
        container('nodejs') {
          sh 'docker build -t $REGISTRY/$REGISTRY_NAMESPACE/$APP_NAME:$APP_VER-$BUILD_NUMBER -f Dockerfile .'
          withCredentials([
            usernamePassword(
              credentialsId: "$REGISTRY_CREDENTIAL_ID",
              passwordVariable: 'HARBOR_PASSWORD',
              usernameVariable: 'HARBOR_USERNAME'
            )
          ]) {
            sh 'echo "$HARBOR_PASSWORD" | docker login $REGISTRY -u "$HARBOR_USERNAME" --password-stdin'
            sh 'docker push $REGISTRY/$REGISTRY_NAMESPACE/$APP_NAME:$APP_VER-$BUILD_NUMBER'
          }
        }
      }
    }

    stage('Deploy to Staging') {
      steps {
        container('nodejs') {
          withCredentials([
            kubeconfigFile(
              credentialsId: env.KUBECONFIG_CREDENTIAL_ID,
              variable: 'KUBECONFIG'
            )
          ]) {
            sh 'envsubst < deploy/deploy-deployment.yaml | kubectl apply -f -'
            sh 'envsubst < deploy/deploy-service.yaml | kubectl apply -f -'
          }
        }
      }
    }
  }
}
