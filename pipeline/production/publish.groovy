def remote = [:]
pipeline {
    agent {
        label 'master'
    }
    options {
        ansiColor('gnome-terminal')
    }
    environment {
        SYSADMIN_RSA = '0dd067b6-8bd0-4c0a-9cb7-fb374ed7084e'
        TARGET_TAG = "$params.RELEASE_TAG"
        VERSION_CORE = "${params.RELEASE_TAG.split('\\+')[0].split('-')[0]}"
        //CHANGE
        REMOTE_ANS_NAME = "ansible-server"
        PROP_BUILD_ENVIRONMENT = "${env.BUILD_ENVIRONMENT}"
        PROP_REMOTE_ANS_HOST = "${env.REMOTE_ANS_HOST}"
        PROP_DOWNSTREAM_JIRA_JOB = "${env.JIRA_JOB}"
        PROP_APP_DOWNLOAD_LINK = "${env.APP_DOWNLOAD_LINK }"
    }
    stages {
        stage('Publish APK') {
            steps {
                cleanWs()
                withEnv(["PublishTag=${params.RELEASE_TAG}"]) {
                    script {
                        remote.name = "$REMOTE_ANS_NAME"
                        remote.host = "$PROP_REMOTE_ANS_HOST"
                        remote.allowAnyHosts = true
                        currentBuild.displayName = "[${PROP_BUILD_ENVIRONMENT}] ${PublishTag}"
                        withCredentials([sshUserPrivateKey(credentialsId: "$SYSADMIN_RSA", keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'user')]) {
                            remote.identityFile = identity
                            remote.user = user
                            writeFile file: 'version', text: ''
                            sshGet remote: remote, from: '/data-disk/mobile-deployment-document/android.version', into: 'version', override: true
                            env.CURRENT_ONLINE_TAG = readFile('version').trim()
                            echo "$PROP_BUILD_ENVIRONMENT version = $CURRENT_ONLINE_TAG"
                            sshCommand remote: remote, command: """
                                ansible-playbook -v /data-disk/brand-deployment-document/playbooks/deploy-kto-android-apk.yml --extra-vars "tag=$PublishTag"
                                echo $PublishTag > /data-disk/mobile-deployment-document/android.version
                            """
                        }
                    }

                }
            }
        }

        stage('Update jira issues') {
            steps {
                withEnv(["JOB=$PROP_DOWNSTREAM_JIRA_JOB",
                         "TARGET=$TARGET_TAG",
                         "CURRENT=$CURRENT_ONLINE_TAG",
                         "ENV=${PROP_BUILD_ENVIRONMENT.toLowerCase()}"
                ]) {
                    build job: "$PROP_DOWNSTREAM_JIRA_JOB", parameters: [text(name: 'TARGET_TAG', value: "$TARGET_TAG"),
                                                                         text(name: 'CURRENT_ONLINE_TAG', value: "$CURRENT"),
                                                                         text(name: 'ENV', value: "$ENV")]
                }
            }
        }

        stage('Notification') {
            steps {
                script {
                    withEnv(["PUBLISH_TAG=${params.RELEASE_TAG}",
                             "ENVIRONMENT=${PROP_BUILD_ENVIRONMENT.toLowerCase()}",
                             "VERSION=$VERSION_CORE",
                             "TEAMS_TOKEN=${env.TEAMS_NOTIFICATION}",
                             "DownloadLink=$PROP_APP_DOWNLOAD_LINK"
                    ]) {
                        String path = PUBLISH_TAG.split('+')[0]
                        office365ConnectorSend webhookUrl: "$TEAMS_NOTIFICATION",
                                message: ">**[Android] [KTO Asia]** has been deployed to $ENVIRONMENT</br>version : **[$PUBLISH_TAG]($PROGET_HOME/feeds/app/android/kto-asia/${path}/files)**",
                                factDefinitions: [[name: "Download Page", template: "<a href=\"$DownloadLink\">Download Page</a>"],
                                                  [name: "Related Issues", template: "<a href=\"https://jira.higgstar.com/issues/?jql=project = APP AND labels = android-$VERSION-$ENVIRONMENT\">Jira Issues</a>"]]
                    }
                }
            }
        }
    }
}
