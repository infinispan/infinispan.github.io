#!/usr/bin/env groovy

pipeline {
    agent {
        label 'ec2'
    }
    
    environment {
        MAVEN_HOME = tool('Maven')
        JAVA_HOME = tool('JDK 8')
        PATH = "$MAVEN_HOME:$JAVA_HOME/bin:$HOME/bin:$PATH"
    }

    options {
        timeout(time: 3, unit: 'HOURS')
    }

    stages {
        stage('Prepare') {
            steps {
                // Show the agent name in the build list
                script {
                    // The manager variable requires the Groovy Postbuild plugin
                    manager.addShortText(env.NODE_NAME, "grey", "", "0px", "")
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Publish') {
            steps {
                echo "Using PATH = ${env.PATH}"
                sh "./bin/publish_production.sh"
            }
        }        
    }

    post {
        always {
            // Clean
            sh 'git clean -fdx -e "*.hprof" || echo "git clean failed, exit code $?"'
        }
    }
}
