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
        PROP_APPLE_STORE_API_KEY = '63f71ab5-5473-43ca-9191-b34cd19f1fa1'
        PROP_APPLE_STORE_KEY_ID = '2XHCS3W99M'
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
        PROP_FASTLANE_JOB = "$env.FASTLANE_JOB"
        PROP_FASTLANE_TESTFLIGHT_JOB = "$env.FASTLANE_TESTFLIGHT_JOB"
        PROP_PUBLISH_JOB = "$env.PUBLISH_JOB"
        PROP_AUTO_PUBLISH = "$params.AUTO_PUBLISH"
        PROP_API_HOST = "$env.API_HOST" //https://appkto.com
    }

    stages {
        stage('Checkout Online Version') {
            steps {
                echo sh(script: 'env|sort', returnStdout: true)
                cleanWs()
                script {
                    withEnv(["BuildEnviroment=$PROP_BUILD_ENVIRONMENT",
                             "SysAdmin=$PROP_SYSADMIN_RSA",
                             "AnsibleServer=$PROP_REMOTE_ANS_HOST",
                             "ApiHost=$PROP_API_HOST",
                             "PreRelease=$PROP_PRE_REALEASE"
                    ]) {
                        script {
                                // Get Production version
                                withCredentials([sshUserPrivateKey(credentialsId: "$SysAdmin", keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'user')]) {
                                    def remote = [:]
                                    remote.name = 'mis ansible'
                                    remote.host = "$AnsibleServer"
                                    remote.user = user
                                    remote.identityFile = identity
                                    remote.allowAnyHosts = true
                                    def commandResult = sshCommand remote: remote, command: "curl -s ${ApiHost}/ios/api/get-ios-ipa-version | jq -r '.data.ipaVersion'", failOnError : false
                                    echo "$commandResult"
                                    if (commandResult.empty) {
                                        env.CURRENT_ONLINE_TAG = '0.0.1'
                                    } else {
                                        String[] result = commandResult.trim().split('\\+')
                                        if (result.length == 1) {
                                            env.CURRENT_ONLINE_TAG = "${result[0]}-$PreRelease"
                                        } else {
                                            env.CURRENT_ONLINE_TAG = "${result[0]}-$PreRelease+${result[1]}"
                                        }
                                    }
                                    echo "$BuildEnviroment online version = $CURRENT_ONLINE_TAG"
                                }
                        }
                    }
                }
            }
        }
        stage('Define release version') {
            //使用選擇的版本的建置號作為建置號，跟建置要發布的TAG
            agent {
                label 'ios-agent'
            }
            steps {
                script {
                    withEnv(["SelectTag=$params.PARAMS_SELECT_TAG",
                             "OnlineTag=$env.CURRENT_ONLINE_TAG",                             
                             "CredentialsId=$PROP_GIT_CREDENTIALS_ID",
                             "Repo=$PROP_GIT_REPO_URL",
                             "AppleApiKey=$PROP_APPLE_STORE_API_KEY",
                             "PreRelease=$PROP_PRE_REALEASE",
                             "ReleaseVersionCore=$PROP_VERSION_CORE"
                    ]) {
                        checkout([$class: 'GitSCM',
                                    branches: [[name: "refs/tags/$SelectTag"]],
                                    extensions: [[$class: 'ChangelogToBranch',
                                                options: [compareRemote: 'refs',
                                                compareTarget: "tags/$OnlineTag"]],
                                                [$class: 'BuildSingleRevisionOnly']],
                                    userRemoteConfigs: [[credentialsId: "$CredentialsId",
                                                        refspec: '+refs/heads/master:refs/remotes/origin/master +refs/heads/tags/*:refs/remotes/origin/tags/*',
                                                        url: "$Repo"]]])
                        withCredentials([file(credentialsId: "$AppleApiKey", variable: 'API_KEY'),
                                        string(credentialsId: 'ios_agent_keychain_password', variable: 'KEYCHAIN_PASSWORD')
                        ]) {
                            script {
                                // 1 is init version so tag no need to add build number
                                int buildNumber = SelectTag.split('\\+')[1]
                                if (buildNumber == null) {
                                    env.PROP_NEXT_BUILD_NUMBER = 1
                                    env.PROP_RELEASE_TAG = "$ReleaseVersionCore-$PreRelease"
                                }else {
                                    env.PROP_NEXT_BUILD_NUMBER = buildNumber
                                    env.PROP_RELEASE_TAG = "$ReleaseVersionCore-$PreRelease+$env.PROP_NEXT_BUILD_NUMBER"
                                }
                                currentBuild.displayName = "[$PROP_BUILD_ENVIRONMENT] $env.PROP_RELEASE_TAG"
                            }
                        }
                    }
                }
            }
        }

        stage('Build Project') {
            //建置專案
            //上傳到TestFlight, 建置IPA到Proget, 押上建置的版本號TAG
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
                             "BuildJob=$PROP_FASTLANE_JOB",
                             "TestFlightJob=$PROP_FASTLANE_TESTFLIGHT_JOB"
                    ]) {
                        checkout([$class: 'GitSCM',
                                  branches: [[name: "refs/tags/$SelectTag"]],
                                  extensions: [[$class: 'BuildSingleRevisionOnly']],
                                  userRemoteConfigs: [[credentialsId: "$GitCredentialId",
                                                      refspec: '+refs/heads/master:refs/remotes/origin/master +refs/heads/tags/*:refs/remotes/origin/tags/*',
                                                      url: "$BuildRepo"]]])
                        withCredentials([file(credentialsId: "$AppleApiKey", variable: 'API_KEY'),
                                        string(credentialsId: 'ios_agent_keychain_password', variable: 'KEYCHAIN_PASSWORD')]) {
                            withEnv(["KEY_ID=$PROP_APPLE_STORE_KEY_ID"]) {
                                sh """
                                    pod install --repo-update
                                    fastlane $BuildJob buildVersion:$NextBuildNumber appVersion:$ReleaseVersionCore
                                    fastlane $TestFlightJob buildVersion:$NextBuildNumber appVersion:$ReleaseVersionCore
                                """
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
            //建置專案
            //建立Jira Release Version, 如果已經存在就忽略
            //更新所有改變的Jira Issue的 環境Label 跟 Fix-Version
            steps {
                withEnv(["Enviroment=${PROP_BUILD_ENVIRONMENT.toLowerCase()}",
                         "NewVersion=ios-$PROP_VERSION_CORE"
                ]) {
                    script {
                        def issueKeys = jiraIssueSelector(issueSelector: [$class: 'DefaultIssueSelector'])
                        //relase new fix-verion for release candiate
                        jiraNewVersion site: 'Higgs-Jira', failOnError: false, version: [name: "$NewVersion", project: 'APP']
                        def newVersion = [ name:"$NewVersion" ]
                        for (issue in issueKeys) {
                            def result = jiraGetIssue idOrKey:issue, site: 'Higgs-Jira', failOnError: false
                            if (result != null && result.data != null ) {
                                def fixVersions = result.data.fields.fixVersions << newVersion
                                def updateIssue = [fields: [labels: ["$NewVersion-$Enviroment"],
                                                            fixVersions:fixVersions]]
                                response = jiraEditIssue failOnError: false, site: 'Higgs-Jira', idOrKey: "$issue", issue: updateIssue
                            }
                        }
                    }
                }
            }
        }

        stage('Release Notification') {
            steps {
                echo sh(script: 'env|sort', returnStdout: true)
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
                                message: ">**[IOS] [KTO Asia]** has been release to $Enviroment</br>version : **[$PublishTag]($JENKINS_PROGET_HOME/feeds/app/ios/kto-asia/${path}/files)**",
                                factDefinitions: [[name: 'Download Page', template: "<a href=\"$DownloadLink\">link</a>"],
                                                  [name: 'Update Issues', template: "$online->$publish (<a href=\"$UpdateIssues\">issues</a>)"],
                                                  [name: 'Release Issues', template: "<a href=\"$TotalIssues\">Jira Issues</a>"]]
                    }
                }
            }
        }

        stage('Auto Trigger publish') {
            when {
                expression { PROP_AUTO_PUBLISH !=null && PROP_AUTO_PUBLISH == true }
            }
            steps {
                build wait: false, job: "$PROP_PUBLISH_JOB", parameters: [text(name: 'PROP_RELEASE_TAG', value: "$env.PROP_RELEASE_TAG")]
            }
        }
    }
}
