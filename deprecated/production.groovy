def ONLINE_VERSION = '0.0.0'
def PUBLISH_VERSION = params.PRO_TAG.split('-')[0]
pipeline {
    agent {
        label 'master'
    }
    stages {
        stage('Double confirm') {
            steps {
                script {
                    currentBuild.displayName = "[Final] ${PUBLISH_VERSION}#${BUILD_NUMBER}"
                    def userInput = input(
                            id: 'userInput', message: "Publish $params.PRO_TAG to Producation!!",
                            parameters: [[$class: 'BooleanParameterDefinition', defaultValue: false, description: '', name: "Please confirm you sure to process?"]]
                    )
                    if (!userInput) {
                        error "Build wasn't confirmed"
                    }
                }
            }

        }
        stage('Compare git version') {
            steps {
                script {
                    ONLINE_VERSION = sh(
                            script: "ssh sysadmin@10.10.16.16 cat /data-disk/mobile-deployment-document/android.version",
                            returnStdout: true
                    ).trim()
                    echo ONLINE_VERSION
                }
                checkout([$class: 'GitSCM', branches: [[name: "refs/tags/$params.PRO_TAG"]], browser: [$class: 'GitLab', repoUrl: 'https://gitlab.higgstar.com/mobile/kto-asia-android', version: '14.4'], extensions: [[$class: 'ChangelogToBranch', options: [compareRemote: 'refs', compareTarget: "tags/${ONLINE_VERSION}-pro"]], [$class: 'AuthorInChangelog'], [$class: 'BuildSingleRevisionOnly']], userRemoteConfigs: [[credentialsId: '28ef89bf-70a2-475d-b5e0-a1ea12a8fcdb', url: 'git@gitlab.higgstar.com:mobile/kto-asia-android.git']]])
                script {
                    if (currentBuild.changeSets.isEmpty()) {
                        error "No changes found!!"
                    }
                }
            }
        }
        stage('Publish apk to production') {
            steps {
                script {
                    def result = sh(
                            script: "ssh sysadmin@10.10.16.16 /data-disk/mobile-deployment-document/deploy_release_version.sh $PUBLISH_VERSION",
                            returnStdout: true
                    )
                    if(result != 0) {
                        error "Deploy Error!!"
                    }
                }

            }
        }
        stage('Finish jira issues') {
            steps {
                build job: '(Final) Production Step.2 Update Jira', parameters: [text(name: 'ONLINE_RC_TAG', value: "${ONLINE_VERSION}-pro"), text(name: 'PUBLISH_RC_TAG', value: "${params.PRO_TAG}")]
            }
        }
    }
}
