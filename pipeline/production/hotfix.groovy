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
        ANDROID_KEYSTORE = 'ab4e5234-c045-442c-a8e2-6a31a63aeb6c'
        PROP_BUILD_ENVIRONMENT = "${env.ENV_BUILD_ENVIRONMENT}"
        PROP_BUILD_TASK = "${env.ENV_BUILD_TASK}"
        PROP_PRE_REALEASE = "${env.ENV_PRE_RELEASE}"
        PROP_DOWNSTREAM_JIRA_JOB = "${env.ENV_DOWNSTREAM_JIRA_JOB}"
        PROP_TEAMS_NOTIFICATION = "${env.ENV_TEAMS_NOTIFICATION_TOKEN}"
    }
    stages {
        stage('Init workspace') {
            steps {
                cleanWs()
                withEnv(["TargetBranch=${params.PARAMS_HOTFIX_BRANCH}",
                         "BuildEnviroment=${PROP_BUILD_ENVIRONMENT}",
                         "Prelease=${PROP_PRE_REALEASE}"
                ]) {
                    script {
                        def remote = [
                            'name'         : 'production ansible-server',
                            'host'         : '10.10.16.16',
                            'allowAnyHosts': true
                        ]
                        withCredentials([sshUserPrivateKey(credentialsId: "$SYSADMIN_RSA", keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'user')]) {
                            remote.identityFile = identity
                            remote.user = user
                            writeFile file: 'version', text: ''
                            sshGet remote: remote, from: '/data-disk/mobile-deployment-document/android.version', into: 'version', override: true
                            env.PROP_PRODUCTION_TAG = readFile('version').trim()
                            echo "$BuildEnviroment version = $PROP_PRODUCTION_TAG"
                        }
                        String version = TargetBranch.findAll('[0-9]+.[0-9]+.[0-9]+')[0]
                        if (version == null) {
                            error('Failing build because not a production valid branch x.x.x')
                        }
                        echo "Compare latest version: $PROP_PRODUCTION_TAG"
                        echo sh(script: 'env|sort', returnStdout: true)
                        Date date = new Date()
                        env.PROP_VERSION_CORE = "$version"
                        env.PROP_RELEASE_TAG =  "$version-$Prelease.${date.format('MMddHHmm')}"
                        echo "Create HotFix Tag $PROP_RELEASE_TAG"
                        currentBuild.displayName = "[$BuildEnviroment] $PROP_RELEASE_TAG"
                    }
                }
            }
        }

        stage('Build Hotfix Version') {
            steps {
                dir('project') {
                    withEnv(["ReleaseTag=$PROP_RELEASE_TAG",
                             "OnlineTag=$PROP_PRODUCTION_TAG",
                             "BuildNumber=${params.BUILD_NUMBER}",
                             "TargetBranch=${params.PARAMS_HOTFIX_BRANCH}",
                             "Repo=$GIT_REPO_URL",
                             "CredentialId=$GIT_CREDENTIALS_ID",
                             "Keystore=$ANDROID_KEYSTORE",
                             "Task=$PROP_BUILD_TASK",
                             "OutputFolder=app/build/outputs/apk/${PROP_BUILD_ENVIRONMENT.toLowerCase()}/release",
                             "OutputFile=KtoAisaBet_${PROP_BUILD_ENVIRONMENT.toLowerCase()}_v$PROP_RELEASE_TAG-signed.apk",
                             "RenameFile=KtoAisaBet_v$PROP_RELEASE_TAG-signed.apk"
                    ]) {
                        echo sh(script: 'env|sort', returnStdout: true)
                        checkout([$class           : 'GitSCM',
                                  branches         : [[name: "$TargetBranch"]],
                                  browser          : [$class: 'GitLab', repoUrl: "$REPO", version: '14.4'],
                                  extensions       : [[$class: 'ChangelogToBranch', options: [compareRemote: 'refs', compareTarget: "tags/$OnlineTag"]],
                                                      [$class: 'AuthorInChangelog'],
                                                      [$class: 'BuildSingleRevisionOnly']],
                                  userRemoteConfigs: [[credentialsId: "$CredentialId",
                                                       refspec      : "+refs/heads/$TargetBranch:refs/remotes/origin/$TargetBranch +refs/heads/tags/*:refs/remotes/origin/tags/*",
                                                       url          : "$Repo"]]
                        ])
                        echo "Release $TargetBranch , $ReleaseTag"
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
                            sh "mv $OutputFolder/$OutputFile $OutputFolder/$RenameFile"
                            uploadProgetPackage artifacts: "[$OutputFolder]/$RenameFile",
                                    feedName: 'app',
                                    groupName: 'android',
                                    packageName: 'kto-asia',
                                    version: "$ReleaseTag",
                                    description: "compile version:$BuildNumber"
                        }
                    }
                }
            }
        }

        stage('Publish APK to QAT3') {
            steps {
                withEnv(["ReleaseTag=$PROP_RELEASE_TAG",
                         "SysAdminCredentialId=$GIT_CREDENTIALS_ID",
                         'MisAnsibleCredentialId=2cb1ac3a-2e81-474e-9846-25fad87697ef',
                         "GitRepo=$GIT_REPO_URL",
                         "BuildEnviroment=$PROP_BUILD_ENVIRONMENT"
                ]) {
                    withCredentials([sshUserPrivateKey(credentialsId: "$MisAnsibleCredentialId", keyFileVariable: 'keyFile', passphraseVariable: '', usernameVariable: 'username')]) {
                        script {
                            def remote = [:]
                            remote.name = 'mis ansible'
                            remote.host = 'mis-ansible-app-01p'
                            remote.user = 'root'
                            remote.allowAnyHosts = true
                            remote.identityFile = keyFile
                            sshCommand remote: remote, command: """
                                ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_TIMEOUT=30; ansible-playbook -v /data-disk/brand-team/deploy-kto-android-apk.yml -u root --extra-vars "apkFeed=kto-asia tag=$ReleaseTag" -i /data-disk/brand-team/qat3.ini
                            """
                        }
                    }
                    wrap([$class: 'BuildUser']) {
                        sshagent(["$SysAdminCredentialId"]) {
                            sh """
                            cd project
                            git config user.name "devops"
                            git tag -f -a -m "release $BuildEnviroment version from ${params.BUIlD_USER}" $ReleaseTag
                            git push $GitRepo $ReleaseTag
                            """
                        }
                    }
                }
            }
        }

        stage('Update jira issues') {
            steps {
                withEnv(["ReleaseTag=$PROP_RELEASE_TAG",
                         "ProductionTag=$PROP_PRODUCTION_TAG"
                ]) {
                    build job: '(Hot-Fix) Qat3 Publish Step - Update Jira',
                            parameters: [text(name: 'CURRENT_TAG', value: "$ProductionTag"),
                                         text(name: 'RELEASE_TAG', value: "$ReleaseTag")]
                }
            }
        }

        stage('Notification') {
            steps {
                script {
                    withEnv(["PublishTag=$PROP_RELEASE_TAG",
                             "BuildEnviroment=${PROP_BUILD_ENVIRONMENT.toLowerCase()}",
                             "Version=$PROP_VERSION_CORE",
                             "TeamsToken=$PROP_TEAMS_NOTIFICATION",
                             "ProgetHome=$PROGET_HOME"
                    ]) {
                        office365ConnectorSend webhookUrl: "$TeamsToken",
                                message: ">**[Android] [KTO Asia]** has been deployed to $BuildEnviroment</br>version : **[$PublishTag]($ProgetHome/feeds/app/android/kto-asia/$Version/files)**",
                                factDefinitions: [[name: 'Download Page', template: '<a href="https://qat3-mobile.affclub.xyz/">Download Page</a>'],
                                                  [name: 'Related Issues', template: "<a href=\"https://jira.higgstar.com/issues/?jql=project = APP AND labels = android-$Version-$BuildEnviroment\">Jira Issues</a>"]]
                    }
                }
            }
        }
    }
}
