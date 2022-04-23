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
        VERSION_CORE = "${params.ReleaseTag.split('\\+')[0].split('-')[0]}"
        REMOTE_ANS_NAME = "ansible-server"
        PROP_BUILD_ENVIRONMENT = "${env.BUILD_ENVIRONMENT}"
        PROP_REMOTE_ANS_HOST = "${env.REMOTE_ANS_HOST}"
        PROP_DOWNSTREAM_JIRA_JOB = "${env.JIRA_JOB}"
        PROP_PRE_REALEASE = "${env.PRE_RELEASE}"
        PROP_BUILD_TASK = "${env.BUILD_TASK}"
    }
    stages {
        stage("Checkout Online Version") {
            environment {
                BUILD = "${env.BUILD_NUMBER}"
            }
            steps {
                cleanWs()
                script {
                    def remote = [
                            'name'         : "$REMOTE_ANS_NAME",
                            'host'         : "$PROP_REMOTE_ANS_HOST",
                            'allowAnyHosts': true
                    ]
                    env.SEMANTIC_ENV_VERSION = "$VERSION_CORE"
                    if (PROP_PRE_REALEASE?.trim()) {
                        env.SEMANTIC_ENV_VERSION = "$VERSION_CORE-${PRE_RELEASE}"
                    }
                    env.RELEASE_TAG = "$SEMANTIC_ENV_VERSION+$BUILD"
                    echo "Release tag : $RELEASE_TAG"
                    currentBuild.displayName = "[$PROP_BUILD_ENVIRONMENT] ${RELEASE_TAG}"
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
                    withEnv(["ReleaseTag=$RELEASE_TAG",
                             "BUILD_NUMBER=${env.BUILD_NUMBER}",
                             "SelectTag=$params.ReleaseTag",
                             "REPO=${GIT_REPO_URL}",
                             "CREDENTIALS_ID=${GIT_CREDENTIALS_ID}",
                             "KEYSTORE=${ANDROID_KEYSTORE}",
                             "TASK=$PROP_BUILD_TASK",
                             "PROGET_APK_REPO=${env.PROGET_HOME}/feeds/app/android/kto-asia/${VERSION_CORE}/files",
                             "OUTPUT_FOLDER=app/build/outputs/apk/${PROP_BUILD_ENVIRONMENT.toLowerCase()}/release",
                             "OUTPUT_FILE=KtoAisaBet_${PROP_BUILD_ENVIRONMENT.toLowerCase()}_v$RELEASE_TAG-signed.apk",
                             "RENAME_FILE=KtoAisaBet_v$RELEASE_TAG-signed.apk"
                    ]) {
                        echo sh(script: 'env|sort', returnStdout: true)
                        checkout([$class           : 'GitSCM',
                                  branches         : [[name: "refs/tags/$SelectTag"]],
                                  browser          : [$class: 'GitLab', repoUrl: "$REPO", version: '14.4'],
                                  extensions       : [[$class: 'ChangelogToBranch', options: [compareRemote: 'refs', compareTarget: "tags/${CURRENT_ONLINE_TAG}"]],
                                                      [$class: 'AuthorInChangelog'],
                                                      [$class: 'BuildSingleRevisionOnly']],
                                  userRemoteConfigs: [[credentialsId: "$GIT_CREDENTIALS_ID",
                                                       refspec      : '+refs/heads/master:refs/remotes/origin/master +refs/heads/tags/*:refs/remotes/origin/tags/*',
                                                       url          : "$REPO"]]
                        ])
                        echo "Release tag : ${env.RELEASE_TAG}"
                        withGradle {
                            sh './gradlew -Porg.gradle.daemon=true -Porg.gradle.parallel=true \"-Porg.gradle.jvmargs=-Xmx4096m -XX:MaxPermSize=4096m -XX:+UseParallelGC\" -Porg.gradle.configureondemand=true $TASK'
                        }
                        signAndroidApks(
                                keyStoreId: "$KEYSTORE",
                                keyAlias: "kto",
                                apksToSign: "app/build/outputs/apk/**/*.apk",
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
                                    description: "compile version:$BUILD_NUMBER"
                        }
                        wrap([$class: 'BuildUser']) {
                            sshagent(["$CREDENTIALS_ID"]) {
                                sh """
                                git config user.name "devops"
                                git tag -f -a -m "release ${PROP_BUILD_ENVIRONMENT.toLowerCase()} version from ${env.BUIlD_USER}" $ReleaseTag
                                git push -f $REPO $ReleaseTag
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
                withEnv(["REPO=${DEVOPS_REPO_URL}",
                         "CREDENTIALS_ID=${GIT_CREDENTIALS_ID}",
                         "ReleaseTag=$RELEASE_TAG",
                         "NAME=kto-asia"
                ]) {
                    git changelog: false, credentialsId: "$CREDENTIALS_ID", url: "$REPO"
                    ansiblePlaybook becomeUser: null, installation: 'ansible', playbook: 'rc/rc-rsync.yml', sudoUser: null, extras: "-v -e \"tag=$ReleaseTag apkFeed=$NAME\""
                    echo('wait 5 minuties')
                    sleep time: 5, unit: 'MINUTES'
                }
            }
        }

        stage('Update jira issues') {
            steps {
                script {
                    withEnv(["CURRENT_TAG=$CURRENT_ONLINE_TAG",
                             "RELEASE_TAG=$RELEASE_TAG",
                             "RELEASE_VERSION=$VERSION_CORE",
                             "ENVIRONMENT=${PROP_BUILD_ENVIRONMENT.toLowerCase()}"
                    ]) {
                        build job: "$PROP_DOWNSTREAM_JIRA_JOB",
                                parameters: [text(name: 'CURRENT_ONLINE_TAG', value: "${CURRENT_ONLINE_TAG}"),
                                             text(name: 'RELEASE_TAG', value: "$RELEASE_TAG"),
                                             text(name: 'RELEASE_VERSION', value: "$RELEASE_VERSION"),
                                             text(name: 'ENV', value: "$ENVIRONMENT")]
                    }
                }
            }
        }
    }
}
