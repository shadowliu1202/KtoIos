def CURRENT_DEV_TAG = "0.0.0"
def RELEASE_DEV_VERSION = "0.0.0"
def remote = [:]
remote.name = 'mis ansible'
remote.host = 'mis-ansible-app-01p'
remote.user = 'root'
remote.allowAnyHosts = true
pipeline {
    agent {
        label 'master'
    }
    options {
        ansiColor('gnome-terminal')
    }
    environment {
        GIT_CREDENTIALS_ID = '28ef89bf-70a2-475d-b5e0-a1ea12a8fcdb'
        GIT_REPO_URL = 'git@gitlab.higgstar.com:mobile/kto-asia-android.git'
        ANDROID_KEYSTORE = 'ab4e5234-c045-442c-a8e2-6a31a63aeb6c'
        GIT_REPO_BRANCH = 'master'
        QAT_NOTIFICATION = 'https://higgstar.webhook.office.com/webhookb2/9b048c31-83f5-44dc-ae45-bb317534b066@8e771fc0-280e-4271-a200-ad98dd5f6605/IncomingWebhook/5730b6139d2042b69b522e0e5c850403/dbab47a2-891a-470f-a94e-4dbb41d9acbc'
        PROP_BUILD_ENVIRONMENT = "${env.BUILD_ENVIRONMENT}"
        PROP_DOWNSTREAM_JIRA_JOB = "${env.JIRA_JOB}"
        PROP_PRE_REALEASE = "${env.PRE_RELEASE}"
        PROP_BUILD_TASK = "${env.BUILD_TASK}"
        PROP_STAGING_JOB = "${env.STAGING_JOB}"
    }
    parameters {
        booleanParam defaultValue: false, description: '連Staging一起release', name: 'INCLUDE_STAGING'
    }

    stages {
        stage("Init workspace") {
            steps {
                cleanWs()
                script {
                    CURRENT_DEV_TAG = sh(
                            script: """
                                git ls-remote --tags --sort="v:refname" git@gitlab.higgstar.com:mobile/kto-asia-android.git | tail -n1 | sed 's/.*\\///; s/\\^{}//' 
                            """,
                            returnStdout: true
                    ).trim()
                    echo "Compare latest version: $CURRENT_DEV_TAG"
                    echo sh(script: 'env|sort', returnStdout: true)
                }
            }
        }

        stage('Build QAT Project') {
            steps {
                dir('project') {
                    checkout([$class: 'GitSCM', branches: [[name: 'refs/heads/master']], extensions: [[$class: 'ChangelogToBranch', options: [compareRemote: 'refs', compareTarget: "tags/$CURRENT_DEV_TAG"]], [$class: 'BuildSingleRevisionOnly']], userRemoteConfigs: [[credentialsId: "$GIT_CREDENTIALS_ID", refspec: '+refs/heads/master:refs/remotes/origin/master +refs/heads/tags/*:refs/remotes/origin/tags/*', url: 'git@gitlab.higgstar.com:mobile/kto-asia-android.git']]])

                    script {
                        // === workaround for plugin ===
                        sh "mv build.gradle temp.gradle"
                        echo "Project Current Tag : ${currentVersion()}"
                        RELEASE_DEV_VERSION = nextVersion(preRelease: 'dev')
                        sh "mv temp.gradle build.gradle"
                        // === workaround for plugin ===

                        env.RELEASE_TAG = "$RELEASE_DEV_VERSION+${env.BUILD_NUMBER}"
                        currentBuild.displayName = "[QAT] ${RELEASE_TAG}"

                        withEnv(["ReleaseTag=$RELEASE_TAG",
                                 "TASK=$PROP_BUILD_TASK",
                                 "BUILD_NUMBER=${env.BUILD_NUMBER}",
                                 "OUTPUT_FOLDER=app/build/outputs/apk/${PROP_BUILD_ENVIRONMENT.toLowerCase()}/release",
                                 "OUTPUT_FILE=KtoAisaBet_${PROP_BUILD_ENVIRONMENT.toLowerCase()}_v$RELEASE_TAG-signed.apk",
                                 "RENAME_FILE=KtoAisaBet_v$RELEASE_TAG-signed.apk"
                        ]) {
                            withGradle {
                                sh './gradlew -Porg.gradle.daemon=true -Porg.gradle.parallel=true \"-Porg.gradle.jvmargs=-Xmx4096m -XX:MaxPermSize=4096m -XX:+UseParallelGC\" -Porg.gradle.configureondemand=true $TASK'
                            }
                            signAndroidApks(
                                    keyStoreId: "$ANDROID_KEYSTORE",
                                    keyAlias: "kto",
                                    apksToSign: "app/build/outputs/apk/**/*.apk",
                                    androidHome: env.ANDROID_HOME,
                                    zipalignPath: env.ANDROID_ZIPALIGN,
                                    skipZipalign: true
                            )
                            sh "mv $OUTPUT_FOLDER/$OUTPUT_FILE $OUTPUT_FOLDER/$RENAME_FILE"
                            uploadProgetPackage artifacts: "[$OUTPUT_FOLDER]/$RENAME_FILE", feedName: 'app', groupName: 'android', packageName: 'kto-asia', version: "$ReleaseTag", description: "compile version:$BUILD_NUMBER"
                        }
                    }
                }
            }
        }

        stage('Publish APK to Ansible') {
            steps {
                withEnv(["ReleaseTag=$RELEASE_TAG"]) {
                    withCredentials([sshUserPrivateKey(credentialsId: '2cb1ac3a-2e81-474e-9846-25fad87697ef', keyFileVariable: 'keyFile', passphraseVariable: '', usernameVariable: 'username')]) {
                        script {
                            remote.identityFile = keyFile
                        }
                        sshCommand remote: remote, command: """                        
                        ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_TIMEOUT=30; ansible-playbook -v /data-disk/brand-team/deploy-kto-android-apk.yml -u root --extra-vars "apkFeed=kto-asia tag=$ReleaseTag" -i /data-disk/brand-team/qat1.ini                                                          
                   """
                    }
                    wrap([$class: 'BuildUser']) {
                        sshagent(["${GIT_CREDENTIALS_ID}"]) {
                            sh """
                            cd project 
                            git config user.name "devops"
                            git tag -f -a -m "release $PROP_BUILD_ENVIRONMENT version from ${env.BUIlD_USER}" $ReleaseTag
                            git push $GIT_REPO_URL $ReleaseTag
                        """
                        }
                    }
                }
            }

        }
        stage('Trigger staging publish') {
            when {
                expression { INCLUDE_STAGING == true }
            }
            steps {
                build wait: false, job: "$PROP_STAGING_JOB", parameters: [text(name: 'ReleaseTag', value: "$RELEASE_TAG")]
            }
        }
        stage('Update jira issues') {
            steps {
                script {
                    build job: '(Development) Qat Publish Step - Update Jira',
                            parameters: [text(name: 'CURRENT_DEV_TAG', value: "${CURRENT_DEV_TAG}"),
                                         text(name: 'RELEASE_TAG', value: "$RELEASE_TAG")]
                }
            }
        }

        stage('Notification') {
            steps {
                script {
                    def version = RELEASE_DEV_VERSION.split('-')[0]
                    office365ConnectorSend webhookUrl: "$QAT_NOTIFICATION",
                            message: ">**[Android] [KTO Asia]** has been deployed to QAT</br>version : **[$RELEASE_TAG]($PROGET_HOME/feeds/app/android/kto-asia/$RELEASE_DEV_VERSION/files)**",
                            factDefinitions: [[name: "Download Page", template: '<a href="https://qat1-mobile.affclub.xyz/">Download Page</a>'],
                                              [name: "Related Issues", template: "<a href=\"https://jira.higgstar.com/issues/?jql=project = APP AND labels = android-${version}-qat\">Jira Issues</a>"]]

                }
            }
        }
    }
}
