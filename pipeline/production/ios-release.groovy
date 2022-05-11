pipeline {
    agent {
        label 'master'
    }
    options {
        ansiColor('gnome-terminal')
    }
    environment {
        //iOS-release
        SYSADMIN_RSA = '0dd067b6-8bd0-4c0a-9cb7-fb374ed7084e'
        PROP_GIT_CREDENTIALS_ID = '28ef89bf-70a2-475d-b5e0-a1ea12a8fcdb'
        PROP_GIT_REPO_URL = 'git@gitlab.higgstar.com:mobile/ktobet-asia-ios.git'
        PROP_APPLE_STORE_API_KEY = '8110d047-b477-4759-a390-f858c2908a24'
        PROP_VERSION_CORE = "${params.PARAMS_SELECT_TAG.split('\\+')[0].split('-')[0]}"
        PROP_BUILD_ENVIRONMENT = "$env.BUILD_ENVIRONMENT"
        PROP_DOWNSTREAM_JIRA_JOB = "$env.JIRA_JOB"
        PROP_PRE_REALEASE = "$env.PRE_RELEASE"
        PROP_AGENT_KEYCHAIN_PASSWORD = 'ios_agent_keychain_password'        
        PROP_DOWNLOAD_LINK = "${params.IOS_DOWNLOAD_URL}"
        PROP_TEAMS_NOTIFICATION = "$env.TEAMS_NOTIFICATION_TOKEN"
        PROP_REMOTE_ANS_NAME = 'stg-ansible-server'
        PROP_REMOTE_ANS_HOST = "$env.REMOTE_ANS_HOST"
        PROP_BUILD_ENVIRONMENT_FULL = "$env.BUILD_ENVIRONMENT_FULL"
        PROP_APP_DOWNLOAD_LINK = "$env.IOS_DOWNLOAD_URL"
    }

    stages {
        stage('Checkout Online Version') {
            steps {
                cleanWs()
                withEnv(["PreRelease=$PROP_PRE_REALEASE",
                          "VersionCore=$PROP_VERSION_CORE",
                          "AnsName=$PROP_REMOTE_ANS_NAME",
                          "AnsHost=$PROP_REMOTE_ANS_HOST",
                          "BuildEnv=$PROP_BUILD_ENVIRONMENT"
                ]) {
                    script {
                        def remote = [
                                'name'         : "$AnsName",
                                'host'         : "$AnsHost",
                                'allowAnyHosts': true
                        ]
                        withCredentials([sshUserPrivateKey(credentialsId: "$SYSADMIN_RSA", keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'user')]) {
                            remote.identityFile = identity
                            remote.user = user
                            writeFile file: 'version', text: ''
                            sshGet remote: remote, from: '/data-disk/mobile-deployment-document/ios.version', into: 'version', override: true
                            env.CURRENT_ONLINE_TAG = readFile('version').trim()
                            echo "$BuildEnv version = $CURRENT_ONLINE_TAG"
                        }
                    }
                }
            }
        }
        stage('Define release version') {
            agent {
                label 'ios-agent'
            }
            steps {
                script {
                    withEnv(["SelectTag=${params.PARAMS_SELECT_TAG}",
                             "OnlineTag=$CURRENT_ONLINE_TAG",
                             "CredentialsId=$PROP_GIT_CREDENTIALS_ID",
                             "Repo=$PROP_GIT_REPO_URL",
                             "AppleApiKey=$PROP_APPLE_STORE_API_KEY",
                             "PreRelease=$PROP_PRE_REALEASE",
                             "ReleaseVersionCore=$PROP_VERSION_CORE",
                    ]) {
                        checkout([$class: 'GitSCM',
                                    branches: [[name: "refs/tags/$SelectTag"]],
                                    extensions: [[$class: 'ChangelogToBranch',
                                                options: [compareRemote: 'refs',
                                                compareTarget: "tags/$OnlineTag"]],
                                                [$class: 'BuildSingleRevisionOnly']],
                                    userRemoteConfigs: [[credentialsId: "$CredentialsId",
                                                        refspec: "+refs/heads/master:refs/remotes/origin/master +refs/heads/tags/*:refs/remotes/origin/tags/*",
                                                        url: "$Repo"]]])
                        withCredentials([file(credentialsId: "$AppleApiKey", variable: 'API_KEY'),
                                        string(credentialsId: 'ios_agent_keychain_password', variable: 'KEYCHAIN_PASSWORD')
                        ]) {
                            sh "fastlane getNextTestflightBuildNumber releaseTarget:$PreRelease targetVersion:$ReleaseVersionCore"
                            script {
                                // 1 is init version so tag no need to add build number
                                int lastBuildNumber = readFile('fastlane/buildNumber').trim() as int
                                env.PROP_NEXT_BUILD_NUMBER = lastBuildNumber + 1
                                env.PROP_RELEASE_TAG = "$ReleaseVersionCore-$PreRelease+$env.PROP_NEXT_BUILD_NUMBER"
                                currentBuild.displayName = "[$PROP_BUILD_ENVIRONMENT] $env.PROP_RELEASE_TAG"
                            }
                        }
                    }
                }
            }
        }

        stage('Build Project') {
            agent {
                label 'ios-agent'
            }
            steps {
                cleanWs()
                dir('project') {
                    withEnv(["SelectTag=${params.PARAMS_SELECT_TAG}",
                             "ReleaseTag=$env.PROP_RELEASE_TAG",
                             "ReleaseVersionCore=$PROP_VERSION_CORE",
                             "AppleApiKey=$PROP_APPLE_STORE_API_KEY",
                             "BuildRepo=$PROP_GIT_REPO_URL",
                             "CurrentTag=$CURRENT_ONLINE_TAG",
                             "GitCredentialId=$PROP_GIT_CREDENTIALS_ID",
                             'MATCH_PASSWORD=password',
                             "PreRelease=$PROP_PRE_REALEASE",
                             "BuildEnviroment=$PROP_BUILD_ENVIRONMENT",
                             "BuildEnviromentFull=$PROP_BUILD_ENVIRONMENT_FULL",
                             "NextBuildNumber=$PROP_NEXT_BUILD_NUMBER",
                             "JenkinsCredentialsId=$PROP_GIT_CREDENTIALS_ID",
                    ]) {
                        checkout([$class: 'GitSCM',
                                  branches: [[name: "refs/tags/$SelectTag"]],
                                  extensions: [[$class: 'BuildSingleRevisionOnly']],
                                  userRemoteConfigs: [[credentialsId: "$GitCredentialId",
                                                      refspec: "+refs/heads/master:refs/remotes/origin/master +refs/heads/tags/*:refs/remotes/origin/tags/*",
                                                      url: "$BuildRepo"]]])
                        withCredentials([file(credentialsId: "$AppleApiKey", variable: 'API_KEY'),
                                        string(credentialsId: 'ios_agent_keychain_password', variable: 'KEYCHAIN_PASSWORD')]) {
                            sh """
                                pod install --repo-update
                                fastlane buildIpaStaging buildVersion:$NextBuildNumber appVersion:$ReleaseVersionCore
                                fastlane uploadstagingToTestflight buildVersion:$NextBuildNumber, appVersion:$ReleaseVersionCore
                            """
                            script {
                                env.IPA_SIZE = sh(script:"du -s -k output/ktobet-asia-ios-${BuildEnviromentFull}.ipa | awk '{printf \"%.2f\\n\", \$1/1024}'",returnStdout: true).trim()
                                echo "Get Ipa Size = $env.IPA_SIZE"
                            }
                        }
                        uploadProgetPackage artifacts: 'output/*.ipa', feedName: 'app', groupName: 'ios', packageName: 'kto-asia', version: "$ReleaseTag", description: "compile version:$NextBuildNumber"
                        wrap([$class: 'BuildUser']) {
                            sshagent(["$GitCredentialId"]) {
                                sh """
                                    git config user.name "devops"
                                    git tag -f -a -m "release $BuildEnviroment version from $env.BUIlD_USER" $ReleaseTag
                                    git push $BuildRepo $ReleaseTag
                                """
                            }
                        }
                    }
                }
            }
        }

        stage('Update jira issues') {
            steps {
                withEnv(["ReleaseVersionCore=$PROP_VERSION_CORE",
                         "Enviroment=${PROP_BUILD_ENVIRONMENT.toLowerCase()}"
                ]) {
                    script {
                        build job: "$PROP_DOWNSTREAM_JIRA_JOB",
                                parameters: [text(name: 'CURRENT_TAG', value: "$env.CURRENT_ONLINE_TAG"),
                                            text(name: 'RELEASE_TAG', value: "$env.PROP_RELEASE_TAG")]
                        def issueKeys = jiraIssueSelector(issueSelector: [$class: 'DefaultIssueSelector'])
                        for (issue in issueKeys) {
                            echo "process $issue"
                            def updateIssue = [fields: [labels: ["android-$ReleaseVersionCore-$Enviroment"]]]
                            jiraEditIssue site: 'Higgs-Jira', idOrKey: "$issue", issue: updateIssue
                        }
                    }
                }
            }
        }

        stage('Release Notification') {
            steps {
                script {
                    withEnv(["PublishTag=$env.PROP_RELEASE_TAG",
                             "OnlineTag=$env.CURRENT_ONLINE_TAG",
                             "Enviroment=${PROP_BUILD_ENVIRONMENT.toLowerCase()}",
                             "TeamsToken=$PROP_TEAMS_NOTIFICATION",
                             "DownloadLink=$PROP_APP_DOWNLOAD_LINK",
                             "UpdateIssues=https://jira.higgstar.com/issues/?jql=project = APP AND labels = ios-$PROP_VERSION_CORE-${PROP_BUILD_ENVIRONMENT.toLowerCase()}",
                             "TotalIssues=https://jira.higgstar.com/issues/?jql=project = APP AND fixVersion = ios-$PROP_VERSION_CORE",
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
