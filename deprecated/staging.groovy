def CURRENT_RC_TAG = "0.0.0"
def RELEASE_RC_TAG = "0.0.0"
def remote = [:]
remote.name = 'inf-ansible-adm-05p'
remote.host = '10.10.16.15'
remote.user = 'sysadmin'
remote.allowAnyHosts = true
pipeline {
    agent {
        label 'master'
    }
    options {
        ansiColor('gnome-terminal')
    }
    environment {
        FEED = "app"
        APK_NAME = "kto-asia"
        ENVIROMENT = "stg"
        SYSADMIN_RSA = '0dd067b6-8bd0-4c0a-9cb7-fb374ed7084e'
        GIT_CREDENTIALS_ID = '28ef89bf-70a2-475d-b5e0-a1ea12a8fcdb'
        GIT_REPO_URL = 'git@gitlab.higgstar.com:mobile/kto-asia-android.git'
        DEVOPS_REPO_URL = 'git@gitlab.higgstar.com:mobile/devops.git'
        ANDROID_KEYSTORE = 'ab4e5234-c045-442c-a8e2-6a31a63aeb6c'
        RELEASE_DEVELOPMENT_TAG = "$params.RC_TAG"
        RELEASE_VERSION = "${params.RC_TAG.split('-')[0]}"
        RELEASE_RC_VERSION = "$RELEASE_VERSION-rc"
        RELEASE_CODE = "${params.RC_TAG.split('\\+')[1]}"
        STG_NOTIFICATION = 'https://higgstar.webhook.office.com/webhookb2/9b048c31-83f5-44dc-ae45-bb317534b066@8e771fc0-280e-4271-a200-ad98dd5f6605/IncomingWebhook/7205498335b74bdaa114779183f17c93/dbab47a2-891a-470f-a94e-4dbb41d9acbc'
    }
    stages {
        stage("Checkout Staging Version") {
            steps {
                cleanWs()
                script {
                    if (RELEASE_CODE == null || RELEASE_CODE.isEmpty()) {
                        RELEASE_CODE = env.BUILD_NUMBER
                    }
                    RELEASE_RC_TAG = "$RELEASE_RC_VERSION+$RELEASE_CODE"
                    currentBuild.displayName = "[Staging] $RELEASE_RC_TAG"
                    withCredentials([sshUserPrivateKey(credentialsId: "$SYSADMIN_RSA", keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'user')]) {
                        remote.identityFile = identity
                        remote.user = user
                        sshGet remote: remote, from: '/data-disk/mobile-deployment-document/android.version', into: 'version', override: true
                        CURRENT_RC_TAG = readFile 'version'
                        echo "Staging version = $CURRENT_RC_TAG"
                    }
                }
            }
        }
        stage('Build APK') {
            steps {
                dir('project') {
                    checkout([$class: 'GitSCM', branches: [[name: "refs/tags/$RELEASE_DEVELOPMENT_TAG"]], browser: [$class: 'GitLab', repoUrl: "$GIT_REPO_URL", version: '14.4'], extensions: [[$class: 'ChangelogToBranch', options: [compareRemote: 'refs', compareTarget: "tags/${CURRENT_RC_TAG}"]], [$class: 'AuthorInChangelog'], [$class: 'BuildSingleRevisionOnly']], userRemoteConfigs: [[credentialsId: "$GIT_CREDENTIALS_ID", refspec: '+refs/heads/master:refs/remotes/origin/master +refs/heads/tags/*:refs/remotes/origin/tags/*', url: "$GIT_REPO_URL"]]])
                    withEnv(["ReleaseTag=$RELEASE_RC_TAG", "BUILD_NUMBER=$RELEASE_CODE"]) {
                        echo sh(script: 'env|sort', returnStdout: true)
                        withGradle {
                            sh './gradlew -Porg.gradle.daemon=true -Porg.gradle.parallel=true \"-Porg.gradle.jvmargs=-Xmx4096m -XX:MaxPermSize=4096m -XX:+UseParallelGC\" -Porg.gradle.configureondemand=true app:clean assembleStgRelease'
                        }
                    }
                    signAndroidApks(
                            keyStoreId: "$ANDROID_KEYSTORE",
                            keyAlias: "kto",
                            apksToSign: "app/build/outputs/apk/**/*.apk",
                            androidHome: env.ANDROID_HOME,
                            zipalignPath: env.ANDROID_ZIPALIGN,
                            skipZipalign: true
                    )
                    script {
                        def output = "app/build/outputs/apk/${env.ENVIROMENT}/release"
                        def fileName = "KtoAisaBet_v${RELEASE_RC_VERSION}-signed.apk"
                        sh "mv $output/KtoAisaBet_${env.ENVIROMENT}_v${RELEASE_VERSION}-signed.apk $output/$fileName"
                        echo "upload $output $fileName"
                        uploadProgetPackage artifacts: "[$output]/$fileName", feedName: 'app', groupName: 'android', packageName: 'kto-asia', version: "$RELEASE_RC_TAG", description: "compile version:$RELEASE_CODE"
                    }

                    wrap([$class: 'BuildUser']) {
                        sshagent(["${GIT_CREDENTIALS_ID}"]) {
                            sh """                                
                                git config user.name "devops"
                                git tag -f -a -m "release development version from ${env.BUIlD_USER}" $RELEASE_RC_TAG
                                git push -f $GIT_REPO_URL $RELEASE_RC_TAG
                            """
                        }
                    }
                }
            }
        }
        stage('Sync APK to FTP') {
            steps {
                git changelog: false, credentialsId: "$GIT_CREDENTIALS_ID", url: "$DEVOPS_REPO_URL"
                ansiblePlaybook becomeUser: null, installation: 'ansible', playbook: 'rc/rc-rsync.yml', sudoUser: null, extras: "-v -e \"version=$RELEASE_RC_VERSION apkFeed=$APK_NAME\""
                echo('wait 5 minuties')
                sleep time: 5, unit: 'MINUTES'
            }
        }

        stage('Publish APK to Staging') {
            steps {

                withCredentials([sshUserPrivateKey(credentialsId: "$SYSADMIN_RSA", keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'user')]) {
                    script {
                        remote.identityFile = identity
                        remote.user = user
                    }
                    sshCommand remote: remote, command: """                       
                        ansible-playbook -v /data-disk/brand-deployment-document/playbooks/deploy-kto-android-apk.yml --extra-vars "tag=$RELEASE_RC_TAG env=$ENVIROMENT"                                                    
                        echo $RELEASE_RC_TAG > /data-disk/mobile-deployment-document/android.version
                   """
                }
                wrap([$class: 'BuildUser']) {
                    sshagent(["${GIT_CREDENTIALS_ID}"]) {
                        sh """
                                cd project 
                                git config user.name "devops"
                                git tag -f -a -m "release development version from ${env.BUIlD_USER}" $RELEASE_RC_TAG
                                git push $GIT_REPO_URL $RELEASE_RC_TAG
                            """
                    }
                }
            }
        }

        stage('Update jira issues') {
            steps {
                script {
                    build job: '(Development) Staging Publish Step - Update Jira',
                            parameters: [text(name: 'CURRENT_RC_TAG', value: "${CURRENT_RC_TAG}"), text(name: 'RELEASE_RC_TAG', value: "$RELEASE_RC_TAG"), text(name: 'RELEASE_VERSION', value: "$RELEASE_VERSION")]
                }
            }

        }

        stage('Notification') {
            steps {
                script {
                    office365ConnectorSend webhookUrl: "$STG_NOTIFICATION",
                            message: ">**[Android] [KTO Asia]** has been deployed to STG</br>version : **[$RELEASE_RC_TAG]($PROGET_HOME/feeds/app/android/kto-asia/$RELEASE_VERSION/files)**",
                            factDefinitions: [[name: "Download Page", template: '<a href="https://https://mobile.staging.support//">Download Page</a>'],
                                              [name: "Related Issues", template: "<a href=\"https://jira.higgstar.com/issues/?jql=project = APP AND labels = android-${RELEASE_VERSION}-stg\">Jira Issues</a>"]]

                }
            }
        }
    }
}
