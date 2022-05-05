pipeline {
    agent {
        label 'master'
    }
    options {
        ansiColor('gnome-terminal')
    }
    environment {
        SYSADMIN_RSA = '0dd067b6-8bd0-4c0a-9cb7-fb374ed7084e'
        GIT_CREDENTIALS_ID = '28ef89bf-70a2-475d-b5e0-a1ea12a8fcdb'
        GIT_REPO_URL = 'git@gitlab.higgstar.com:mobile/kto-asia-android.git'
        DEVOPS_REPO_URL = 'git@gitlab.higgstar.com:mobile/devops.git'
        ANDROID_KEYSTORE = 'ab4e5234-c045-442c-a8e2-6a31a63aeb6c'
        REMOTE_ANS_NAME = 'ansible-server'
        PROP_VERSION_CORE = "${params.PARAMS_SELECT_TAG.split('\\+')[0].split('-')[0]}"
        PROP_BUILD_ENVIRONMENT = "$env.BUILD_ENVIRONMENT"
        PROP_REMOTE_ANS_HOST = "$env.REMOTE_ANS_HOST"
        PROP_DOWNSTREAM_JIRA_JOB = "$env.JIRA_JOB"
        PROP_PRE_REALEASE = "$env.PRE_RELEASE"
        PROP_BUILD_TASK = "$env.BUILD_TASK"
        PROP_TEAMS_NOTIFICATION = "$env.TEAMS_NOTIFICATION_TOKEN"
        PROP_APP_DOWNLOAD_LINK = "$env.APP_DOWNLOAD_LINK"
    }
    stages {
        stage('Checkout Online Version') {
            environment {
                BUILD = "$env.BUILD_NUMBER"
            }
            steps {
                cleanWs()
                script {
                    def remote = [
                            'name'         : "$REMOTE_ANS_NAME",
                            'host'         : "$PROP_REMOTE_ANS_HOST",
                            'allowAnyHosts': true
                    ]
                    env.SEMANTIC_ENV_VERSION = "$PROP_VERSION_CORE"
                    if (PROP_PRE_REALEASE?.trim()) {
                        env.SEMANTIC_ENV_VERSION = "$PROP_VERSION_CORE-$PRE_RELEASE"
                    }
                    env.RELEASE_TAG = "$SEMANTIC_ENV_VERSION+$BUILD"
                    echo "Release tag : $RELEASE_TAG"
                    currentBuild.displayName = "[$PROP_BUILD_ENVIRONMENT] $RELEASE_TAG"
                    withCredentials([sshUserPrivateKey(credentialsId: "$SYSADMIN_RSA", keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'user')]) {
                        remote.identityFile = identity
                        remote.user = user
                        writeFile file: 'version', text: ''
                        sshGet remote: remote, from: '/data-disk/mobile-deployment-document/android.version', into: 'version', override: true
                        env.CURRENT_ONLINE_TAG = readFile('version').trim()
                        echo "$PROP_BUILD_ENVIRONMENT version = $CURRENT_ONLINE_TAG"
                    }
                }
            }
        }
        stage('Build APK') {
            steps {
                dir('project') {
                    withEnv(["ReleaseTag=$env.RELEASE_TAG",
                             "OnlineTag=$env.CURRENT_ONLINE_TAG",
                             "BuildNumber=$env.BUILD_NUMBER",
                             "SelectTag=$params.PARAMS_SELECT_TAG",
                             "Repo=$GIT_REPO_URL",
                             "CredentialId=$GIT_CREDENTIALS_ID",
                             "Keystore=$ANDROID_KEYSTORE",
                             "Task=$PROP_BUILD_TASK",
                             "OUTPUT_FOLDER=app/build/outputs/apk/${PROP_BUILD_ENVIRONMENT.toLowerCase()}/release",
                             "OUTPUT_FILE=KtoAisaBet_${PROP_BUILD_ENVIRONMENT.toLowerCase()}_v$env.RELEASE_TAG-signed.apk",
                             "RENAME_FILE=KtoAisaBet_v$env.RELEASE_TAG-signed.apk"
                    ]) {
                        echo sh(script: 'env|sort', returnStdout: true)
                        checkout([$class           : 'GitSCM',
                                  branches         : [[name: "refs/tags/$SelectTag"]],
                                  browser          : [$class: 'GitLab', repoUrl: "$Repo", version: '14.4'],
                                  extensions       : [[$class: 'ChangelogToBranch', options: [compareRemote: 'refs', compareTarget: "tags/$OnlineTag"]],
                                                      [$class: 'AuthorInChangelog'],
                                                      [$class: 'BuildSingleRevisionOnly']],
                                  userRemoteConfigs: [[credentialsId: "$CredentialId",
                                                       refspec      : '+refs/heads/master:refs/remotes/origin/master +refs/heads/tags/*:refs/remotes/origin/tags/*',
                                                       url          : "$Repo"]]
                        ])
                        echo "Release tag : $ReleaseTag"
                        withGradle {
                            sh "./gradlew -Porg.gradle.daemon=true -Porg.gradle.parallel=true \"-Porg.gradle.jvmargs=-Xmx4096m -XX:MaxPermSize=4096m -XX:+UseParallelGC\" -Porg.gradle.configureondemand=true $Task"
                        }
                        signAndroidApks(
                                keyStoreId: "$Keystore",
                                keyAlias: 'kto',
                                apksToSign: 'app/build/outputs/apk/**/*.apk',
                                androidHome: env.ANDROID_HOME,
                                zipalignPath: env.ANDROID_ZIPALIGN,
                                skipZipalign: true
                        )
                        script {
                            sh "mv $OUTPUT_FOLDER/$OUTPUT_FILE $OUTPUT_FOLDER/$RENAME_FILE"
                            uploadProgetPackage artifacts: "[$OUTPUT_FOLDER]/$RENAME_FILE",
                                    feedName: 'app',
                                    groupName: 'android',
                                    packageName: 'kto-asia',
                                    version: "$ReleaseTag",
                                    description: "compile version:$BuildNumber"
                        }
                        wrap([$class: 'BuildUser']) {
                            sshagent(["$CredentialId"]) {
                                sh """
                                git config user.name "devops"
                                git tag -f -a -m "release ${PROP_BUILD_ENVIRONMENT.toLowerCase()} version from $env.BUIlD_USER" $ReleaseTag
                                git push -f $Repo $ReleaseTag
                            """
                            }
                        }
                    }
                }
            }
        }

        stage('Sync APK to FTP') {
            environment {
                BUILD = "${env.BUILD_NUMBER}"
            }
            steps {
                withEnv(["Repo=${DEVOPS_REPO_URL}",
                         "CredentialId=${GIT_CREDENTIALS_ID}",
                         "ReleaseTag=${env.RELEASE_TAG}",
                         'Name=kto-asia'
                ]) {
                    git changelog: false, credentialsId: "$CredentialId", url: "$Repo"
                    ansiblePlaybook becomeUser: null, installation: 'ansible', playbook: 'rc/rc-rsync.yml', sudoUser: null, extras: "-v -e \"tag=$ReleaseTag apkFeed=$Name\""
                    echo('wait 5 minuties')
                    sleep time: 5, unit: 'MINUTES'
                }
            }
        }

        stage('Update jira issues') {
            steps {
                script {
                    withEnv(["CurrentTag=${env.CURRENT_ONLINE_TAG}",
                             "ReleaseTag=${env.RELEASE_TAG}"
                    ]) {
                        build job: "$PROP_DOWNSTREAM_JIRA_JOB",
                                parameters: [text(name: 'CURRENT_ONLINE_TAG', value: "$CurrentTag"),
                                             text(name: 'RELEASE_TAG', value: "$ReleaseTag")]
                    }
                }
            }
        }

        stage('Release Notification') {
            steps {
                script {
                    withEnv(["PublishTag=$env.RELEASE_TAG",
                             "OnlineTag=$env.CURRENT_ONLINE_TAG",
                             "Enviroment=${PROP_BUILD_ENVIRONMENT.toLowerCase()}",
                             "Version=$PROP_VERSION_CORE",
                             "TeamsToken=$PROP_TEAMS_NOTIFICATION",
                             "DownloadLink=$PROP_APP_DOWNLOAD_LINK",
                             "UpdateIssues=https://jira.higgstar.com/issues/?jql=project = APP AND labels = android-$PROP_VERSION_CORE-${PROP_BUILD_ENVIRONMENT.toLowerCase()}",
                             "TotalIssues=https://jira.higgstar.com/issues/?jql=project = APP AND fixVersion = android-$PROP_VERSION_CORE",
                    ]) {
                        String path = PublishTag.split('\\+')[0]
                        String publish = PublishTag.split('-')[0]
                        String online = OnlineTag.split('-')[0]
                        office365ConnectorSend webhookUrl: "$TeamsToken",
                                message: ">**[Android] [KTO Asia]** has been release to $Enviroment</br>version : **[$PublishTag]($JENKINS_PROGET_HOME/feeds/app/android/kto-asia/${path}/files)**",
                                factDefinitions: [[name: 'Download Page', template: "<a href=\"$DownloadLink\">link</a>"],
                                                  [name: 'Update Issues', template: "$online->$publish (<a href=\"$UpdateIssues\">issues</a>)"],
                                                  [name: 'Release Issues', template: "<a href=\"$TotalIssues\">Jira Issues</a>"]]
                    }
                }
            }
        }
    }
}
