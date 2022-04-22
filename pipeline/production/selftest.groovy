pipeline {
    agent {
        label 'master'
    }
    options {
        ansiColor('gnome-terminal')
    }
    environment {
        SYSADMIN_RSA = "0dd067b6-8bd0-4c0a-9cb7-fb374ed7084e"
        GIT_CREDENTIALS_ID = "28ef89bf-70a2-475d-b5e0-a1ea12a8fcdb"
        GIT_REPO_URL = "git@gitlab.higgstar.com:mobile/kto-asia-android.git"
        DEVOPS_REPO_URL = "git@gitlab.higgstar.com:mobile/devops.git"
        ANDROID_KEYSTORE = "ab4e5234-c045-442c-a8e2-6a31a63aeb6c"
        TARGET_TAG = "$params.ReleaseTag"
        RELEASE_CODE = "${params.ReleaseTag.split('\\+')[1]}"
        RELEASE_VERSION = "${params.ReleaseTag.split('\\+')[0].split('-')[0]}"
    }
    stages {
        stage('Upload APK') {
            steps {
                script {
                    cleanWs()
                    withEnv(["REPO=${GIT_REPO_URL}",
                             "CREDENTIALS_ID=${GIT_CREDENTIALS_ID}",
                             "KEYSTORE=${ANDROID_KEYSTORE}",
                             'TASK=app:clean assemblePro_backupRelease assemblePro_selftestRelease',
                             "PACKAGE_NAME=kto-asia-test",
                             "VERSION_CODE=$RELEASE_CODE",
                             "ReleaseTag=$TARGET_TAG",
                             "BUILD_NUMBER=$RELEASE_CODE"
                    ]) {
                        currentBuild.displayName = "[Pro] $ReleaseTag"
                        dir('project') {
                            checkout([$class: 'GitSCM', branches: [[name: "refs/tags/$ReleaseTag"]], extensions: [[$class: 'AuthorInChangelog'], [$class: 'BuildSingleRevisionOnly']], userRemoteConfigs: [[credentialsId: "$CREDENTIALS_ID", refspec: '+refs/heads/master:refs/remotes/origin/master +refs/heads/tags/*:refs/remotes/origin/tags/*', url: "$REPO"]]])
                            echo sh(script: 'env|sort', returnStdout: true)
                            withGradle {
                                sh "./gradlew -Porg.gradle.daemon=true -Porg.gradle.parallel=true \"-Porg.gradle.jvmargs=-Xmx4096m -XX:MaxPermSize=4096m -XX:+UseParallelGC\" -Porg.gradle.configureondemand=true $TASK"
                            }
                            signAndroidApks(
                                    keyStoreId: "$KEYSTORE",
                                    keyAlias: "kto",
                                    apksToSign: "app/build/outputs/apk/**/*.apk",
                                    androidHome: env.ANDROID_HOME,
                                    zipalignPath: env.ANDROID_ZIPALIGN,
                                    skipZipalign: true
                            )
                            "[one]/one.txt, [two]/two.txt"
                            uploadProgetPackage artifacts: "[app/build/outputs/apk/pro_backup/release]/*-signed.apk, [app/build/outputs/apk/pro_selftest/release]/*-signed.apk", feedName: 'app', groupName: 'android', packageName: "${PACKAGE_NAME}", version: "$ReleaseTag", description: "compile version:$VERSION_CODE"
                        }
                    }
                }
            }
        }

        stage('Notify production release') {
            steps {
                script {
                    echo "notify $TEAMS_NOTIFICATION"
                    withEnv(["REPO=${GIT_REPO_URL}",
                             "ReleaseTag=$TARGET_TAG",
                             "PROGET_APK_REPO=${env.PROGET_HOME}/feeds/app/android/kto-asia/${RELEASE_VERSION}/files",
                             "PROGET_TEST_REPO=${env.PROGET_HOME}/feeds/app/android/kto-asia-test/${RELEASE_VERSION}/files",
                             "OFFICIAL_WEB=https://appkto.com/",
                             "JiraIssues=https://jira.higgstar.com/issues/?jql=project = APP AND fixVersion = android-$RELEASE_VERSION"
                    ]) {
                        office365ConnectorSend webhookUrl: "$TEAMS_NOTIFICATION",
                                message: ">**[Android] [KTO Asia]** has been released for Production</br>version : **[$ReleaseTag]($PROGET_APK_REPO)**",
                                factDefinitions: [[name: "Download Page", template: "<a href=\"$OFFICIAL_WEB\">Download Page</a>"],
                                                  [name: "Issues", template: "<a href=\"$JiraIssues\">Jira Issues</a>"],
                                                  [name: "Self Test", template: "<a href=\"$PROGET_TEST_REPO\">repository</a>"]]
                    }

                }

            }
        }
    }

}
