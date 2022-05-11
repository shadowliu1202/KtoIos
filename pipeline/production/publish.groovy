pipeline {
    agent {
        label 'master'
    }
    options {
        ansiColor('gnome-terminal')
    }
    environment {
        SYSADMIN_RSA = '0dd067b6-8bd0-4c0a-9cb7-fb374ed7084e'
        TARGET_TAG = "$params.PARAMS_SELECT_TAG"
        PROP_VERSION_CORE = "${params.PARAMS_SELECT_TAG.split('\\+')[0].split('-')[0]}"
        //CHANGE
        REMOTE_ANS_NAME = 'ansible-server'
        PROP_BUILD_ENVIRONMENT = "$env.BUILD_ENVIRONMENT"
        PROP_REMOTE_ANS_HOST = "$env.REMOTE_ANS_HOST"
        PROP_DOWNSTREAM_JIRA_JOB = "$env.JIRA_JOB"
        PROP_APP_DOWNLOAD_LINK = "$env.APP_DOWNLOAD_LINK"
        PROP_TEAMS_NOTIFICATION = "$env.TEAMS_NOTIFICATION_TOKEN"
    }
    stages {
        stage('Publish APK') {
            steps {
                cleanWs()
                withEnv(["PublishTag=${params.PARAMS_SELECT_TAG}"]) {
                    script {
                        def remote = [:]
                        remote.name = "$REMOTE_ANS_NAME"
                        remote.host = "$PROP_REMOTE_ANS_HOST"
                        remote.allowAnyHosts = true
                        currentBuild.displayName = "[${PROP_BUILD_ENVIRONMENT}] $PublishTag"
                        withCredentials([sshUserPrivateKey(credentialsId: "$SYSADMIN_RSA", keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'user')]) {
                            remote.identityFile = identity
                            remote.user = user
                            // Get Production version
                            def commandResult = sshCommand remote: remote, command: "curl -s https://appkto.com/android/api/get-android-apk-version | jq -r '.data.apkVersion'"
                            echo "$commandResult"
                            String[] result = commandResult.trim().split('\\+')
                            if (result.length == 1) {
                                env.PRODUCTION_ONLINE_TAG = "${result[0]}-release"
                            } else {
                                env.PRODUCTION_ONLINE_TAG = "${result[0]}-release+${result[1]}"
                            }
                            echo "production version = $PRODUCTION_ONLINE_TAG"
                            // Get Online version
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
                    echo sh(script: 'env|sort', returnStdout: true)
                }
            }
        }

        stage('Update jira issues') {
            steps {
                withEnv(["DownStreamJob=$env.PROP_DOWNSTREAM_JIRA_JOB",
                         "Target=$params.PARAMS_SELECT_TAG",
                         "Current=$env.PRODUCTION_ONLINE_TAG",
                ]) {
                    echo "trigger job $DownStreamJob"
                    build job: "$DownStreamJob" , parameters: [text(name: 'TARGET_TAG', value: "$Target"),text(name: 'PRODUCTION_TAG', value: "$Current")]
                }
            }
        }

        stage('Publish Notification') {
            steps {
                script {
                    withEnv(["PublishTag=$params.PARAMS_SELECT_TAG",
                             "OnlineTag=$env.CURRENT_ONLINE_TAG",
                             "Enviroment=${PROP_BUILD_ENVIRONMENT.toLowerCase()}",
                             "Version=$PROP_VERSION_CORE",
                             "TeamsToken=$PROP_TEAMS_NOTIFICATION",
                             "DownloadLink=$PROP_APP_DOWNLOAD_LINK",
                             "UpdateIssues=https://jira.higgstar.com/issues/?jql=project = APP AND labels = android-$PROP_VERSION_CORE-${PROP_BUILD_ENVIRONMENT.toLowerCase()}",
                    ]) {
                        String path = PublishTag.split('\\+')[0]
                        String publish = PublishTag.split('-')[0]
                        String online = OnlineTag.split('-')[0]
                        office365ConnectorSend webhookUrl: "$TeamsToken",
                                message: ">**[Android] [KTO Asia]** has been published to $Enviroment</br>version : **[$PublishTag]($JENKINS_PROGET_HOME/feeds/app/android/kto-asia/${path}/files)**",
                                factDefinitions: [[name: 'Download Page', template: "<a href=\"$DownloadLink\">link</a>"],
                                                  [name: 'Update Issues', template: "$online->$publish (<a href=\"$UpdateIssues\">issues</a>)"]]
                    }
                }
            }
        }
    }
}
