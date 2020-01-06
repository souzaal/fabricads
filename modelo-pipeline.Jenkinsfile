#!/usr/bin/env groovy
    
    node {
        currentBuild.result = 'SUCCESS'
        def jdktool = tool name: "OpenJDK 1.8", type: 'hudson.model.JDK'
        def mvnHome = tool name: 'Maven 3.0.5'
    
        def MYSQL_DB_NAME = "desenvolvimento"
        def MYSQL_DB_JNDI_NAME = "java:jboss/datasources/portal_mobile"
        def MYSQL_DB_HOST = "xxx.mysql.database.azure.com"
        def MYSQL_DB_PORT = "3306"
        def MYSQL_DB_CONNECTION_PARAMS = "useUnicode=true\\&useJDBCCompliantTimezoneShift=true\\&useLegacyDatetimeCode=false\\&serverTimezone=America/Sao_Paulo\\&useSSL=true\\&requireSSL=false\\&autoReconnect=true"
        def ORACLE_DB_NAME = "XXX"
        def ORACLE_DB_JNDI_NAME = "java:/jdbc/ccm"
        def ORACLE_DB_HOST  = "1.1.1.1"
        def ORACLE_DB_PORT  = "1111"
        def AMBIENTE  = "dev.kubernetes"
        def KEYSTORE_PASS = "***"
        def PREFIX = "dev"
    
        List javaEnv = [
                "PATH+MVN=${jdktool}/bin:${mvnHome}/bin",
                "M2_HOME=${mvnHome}",
                "JAVA_HOME=${jdktool}"
        ]
    
        try {
            stage ('Checkout') {
                git url: 'http://git.web-marisa-visita.com/tipsf/appmarisa/mobileservices.git', branch: 'develop', credentialsId: 'gitlab-root'
            }
    
            withEnv(javaEnv) {
                stage ('Build') {
                    sh 'mvn versions:set -DnextSnapshot=true'
                    sh 'mvn clean package -DskipTests -Dmaven.test.skip=true'
                }
    
                stage('Unit Test') {
                    sh 'mvn test'
                }
    
                stage ('Nexus Deploy') {
                    sh 'mvn deploy -DskipTests -Dmaven.test.skip=true'
                    archiveArtifacts 'target/*.war'
                }
    
                stage('SonarQube') {
                    sh 'mvn sonar:sonar -DskipTests -Dmaven.test.skip=true'
                }
    
                stage('Docker Build') {
                    sh "docker build -t ${ACR_LOGINSERVER}/marisa-mobile-services-dev:v${BUILD_NUMBER} ."
                }
    
                stage('Docker Pull') {
                    withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId:'acr-credentials', usernameVariable: 'ACR_ID', passwordVariable: 'ACR_PASSWORD']]) {
                        sh "docker login ${ACR_LOGINSERVER} -u ${ACR_ID} -p ${ACR_PASSWORD}"
                        sh "docker push ${ACR_LOGINSERVER}/marisa-mobile-services-dev:v${BUILD_NUMBER}"
                    }
                }
    
                stage('Kubernetes Deploy') {
                    withKubeConfig([serverUrl: 'https://clusaks-dev-venus-br-001-dns-ca857ecd.hcp.brazilsouth.azmk8s.io:443', credentialsId: 'kubeconfig', clusterName: 'clusaks-dev-venus-br-001']) {
                        sh "sed -i 's/:VAR_VERSION/-dev:v${BUILD_NUMBER}/g' marisa-mobile-services-deployment.yaml"
                        sh "sed -i 's/VAR_PREFIX/${PREFIX}/g' marisa-mobile-services-deployment.yaml"
                        sh "sed -i 's/VAR_AMBIENTE/${AMBIENTE}/g' marisa-mobile-services-deployment.yaml"
                        sh "sed -i 's/VAR_KEYSTORE_PASS/${KEYSTORE_PASS}/g' marisa-mobile-services-deployment.yaml"
                        sh "sed -i 's/VAR_MYSQL_DB_NAME/${MYSQL_DB_NAME}/g' marisa-mobile-services-deployment.yaml"
                        sh "sed -i 's#VAR_MYSQL_DB_JNDI_NAME#${MYSQL_DB_JNDI_NAME}#g' marisa-mobile-services-deployment.yaml"
                        sh "sed -i 's/VAR_MYSQL_DB_HOST/${MYSQL_DB_HOST}/g' marisa-mobile-services-deployment.yaml"
                        sh "sed -i 's/VAR_MYSQL_DB_PORT/${MYSQL_DB_PORT}/g' marisa-mobile-services-deployment.yaml"
                        sh "sed -i 's#VAR_MYSQL_DB_CONNECTION_PARAMS#${MYSQL_DB_CONNECTION_PARAMS}#g' marisa-mobile-services-deployment.yaml"    
                        sh "sed -i 's/VAR_ORACLE_DB_NAME/${ORACLE_DB_NAME}/g' marisa-mobile-services-deployment.yaml"
                        sh "sed -i 's#VAR_ORACLE_DB_JNDI_NAME#${ORACLE_DB_JNDI_NAME}#g' marisa-mobile-services-deployment.yaml"
                        sh "sed -i 's/VAR_ORACLE_DB_HOST/${ORACLE_DB_HOST}/g' marisa-mobile-services-deployment.yaml"
                        sh "sed -i 's/VAR_ORACLE_DB_PORT/${ORACLE_DB_PORT}/g' marisa-mobile-services-deployment.yaml"
                        sh 'kubectl apply -n=appmarisa-dev -f marisa-mobile-services-deployment.yaml'
                        sh 'kubectl apply -n=appmarisa-dev -f marisa-mobile-services-service.yaml'
                    }
                }
    
             stage('Kubernetes Rollback') {
                withKubeConfig([serverUrl: 'https://clusaks-dev-venus-br-001-dns-ca857ecd.hcp.brazilsouth.azmk8s.io:443', credentialsId: 'kubeconfig', clusterName: 'clusaks-dev-venus-br-001']) {
                    try {
                        timeout(time: 24, unit: 'HOURS') {
                            input(message: 'Rollback deploy?')
                            sh "kubectl rollout undo -n=appmarisa-dev deployment.apps/marisa-mobile-services-deployment"
                        }
                    } catch (err) {
                        // em branco
                    }
                }
            }
        }
    } catch (e) {
        throw e
        currentBuild.result = 'FAILURE'
    }
}
