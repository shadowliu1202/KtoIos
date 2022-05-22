pipeline {
    agent {
        label 'master'
    }
    options {
        ansiColor('gnome-terminal')
    }
    environment {
        PROP_SYSADMIN_RSA = '0dd067b6-8bd0-4c0a-9cb7-fb374ed7084e'
        PROP_ROOT_RSA = '2cb1ac3a-2e81-474e-9846-25fad87697ef'
        PROP_GIT_CREDENTIALS_ID = '28ef89bf-70a2-475d-b5e0-a1ea12a8fcdb'
        PROP_GIT_REPO_URL = 'git@gitlab.higgstar.com:mobile/ktobet-asia-ios.git'
        PROP_APPLE_STORE_API_KEY = '63f71ab5-5473-43ca-9191-b34cd19f1fa1'
        PROP_APPLE_STORE_KEY_ID = '2XHCS3W99M'
        PROP_AGENT_KEYCHAIN_PASSWORD = 'ios_agent_keychain_password'
        PROP_BUILD_ENVIRONMENT = 'Qat3'
        PROP_PRODUCTION_ANS_HOST = '10.10.16.16'
        PROP_BUILD_BRANCH = "$env.HOTFIX_BRNACH".replace('refs/heads/', '')
        PROP_DOWNLOAD_LINK = "$env.DOWNLOAD_URL"
        PROP_TEAMS_NOTIFICATION = "$env.TEAMS_NOTIFICATION"
    }

    stages {
        stage('Diff changes') {
            //取得Production環境的線上版本，
            steps {
                echo sh(script: 'env|sort', returnStdout: true)
                cleanWs()
                script {
                    withEnv(["CredentialsId=$PROP_GIT_CREDENTIALS_ID",
                             "Repo=$PROP_GIT_REPO_URL",
                             "SysAdmin=$PROP_SYSADMIN_RSA",
                             "AnsibleServer=$PROP_PRODUCTION_ANS_HOST",
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
                                    def commandResult = sshCommand remote: remote, command: "curl -s https://appkto.com/ios/api/get-ios-ipa-version | jq -r '.data.ipaVersion'", failOnError : false
                                    echo "$commandResult"
                                    String[] result = commandResult.trim().split('\\+')
                                    if (result.length == 1) {
                                        env.PRODUCTION_ONLINE_TAG = "${result[0]}-release"
                                    } else {
                                        env.PRODUCTION_ONLINE_TAG = "${result[0]}-release+${result[1]}"
                                    }
                                    env.VERSION_CORE = result[0]
                                    echo "production version = $env.PRODUCTION_ONLINE_TAG"
                                }
                        }
                    }
                }
            }
        }

        stage('Build QAT3 project') {
            agent {
                label 'ios-agent'
            }
            steps {
                cleanWs()
                dir('project') {
                    withEnv(["AppleApiKey=$PROP_APPLE_STORE_API_KEY",
                             "BuildRepo=$PROP_GIT_REPO_URL",
                             "GitCredentialId=$PROP_GIT_CREDENTIALS_ID",
                             'MATCH_PASSWORD=password',
                             "BuildBranch=$PROP_BUILD_BRANCH",
                             "OnlineTag=$env.PRODUCTION_ONLINE_TAG",
                             "BuildEnviroment=$PROP_BUILD_ENVIRONMENT",
                             "KEY_ID=$PROP_APPLE_STORE_KEY_ID",
                             "VersionCode=$env.RELEASE_VERSIONCORE",
                             'PreRelease=hotfix'

                    ]) {
                        checkout([$class           : 'GitSCM',
                                  branches         : [[name: "refs/heads/$BuildBranch"]],
                                  browser          : [$class: 'GitLab', repoUrl: "$BuildRepo", version: '14.4'],
                                  extensions       : [[$class: 'ChangelogToBranch', options: [compareRemote: 'refs', compareTarget: "tags/$OnlineTag"]],
                                                      [$class: 'AuthorInChangelog'],
                                                      [$class: 'BuildSingleRevisionOnly']],
                                  userRemoteConfigs: [[credentialsId: "$GitCredentialId",
                                                       refspec      : "+refs/heads/$BuildBranch:refs/remotes/origin/$BuildBranch +refs/heads/tags/*:refs/remotes/origin/tags/*",
                                                       url          : "$BuildRepo"]]
                        ])
                        withCredentials([file(credentialsId: "$AppleApiKey", variable: 'API_KEY'),
                                        string(credentialsId: 'ios_agent_keychain_password', variable: 'KEYCHAIN_PASSWORD')
                        ]){
                            script {
                                env.RELEASE_VERSIONCORE = "${BuildBranch.split('-')[0]}"
                                env.RELEASE_VERSION = "$VersionCode-hotfix.${date.format('MMddHHmm')}"

                                string onlineBuildVersion = OnlineTag.trim().split('\\+')
                                int lastBuildNumber = 1
                                if (onlineBuildVersion.length == 1) {
                                   echo "$OnlineTag has no build number"
                                } else {
                                    lastBuildNumber = (onlineBuildVersion[1] as int)
                                }
                                int testFlightBuildNumber = 0
                                withEnv(["KEY_ID=$PROP_APPLE_STORE_KEY_ID"]) {
                                    def statusCode  = sh script:"fastlane getNextTestflightBuildNumber releaseTarget:$PreRelease targetVersion:$VersionCode", returnStatus:true
                                    if (statusCode == 0) {
                                        testFlightBuildNumber = readFile('fastlane/buildNumber').trim() as int
                                    }
                                }

                                env.NEXT_BUILD_NUMBER = Math.max(lastBuildNumber,testFlightBuildNumber) + 1
                                env.RELEASE_TAG = "$env.RELEASE_VERSION+$env.NEXT_BUILD_NUMBER"
                                currentBuild.displayName = "[$BuildEnviroment] $env.RELEASE_TAG"
                            }
                            sh """
                                pod install --repo-update
                                fastlane buildQat3 buildVersion:$env.NEXT_BUILD_NUMBER appVersion:$env.RELEASE_VERSIONCORE
                            """
                            script {
                                env.IPA_SIZE = sh(script:"du -s -k output/ktobet-asia-ios-${BuildEnviroment.toLowerCase()}.ipa | awk '{printf \"%.2f\\n\", \$1/1024}'", returnStdout: true).trim()
                                echo "Get Ipa Size = $IPA_SIZE"
                            }
                        }
                        uploadProgetPackage artifacts: 'output/*.ipa', feedName: 'app', groupName: 'ios', packageName: 'kto-asia', version: "$env.RELEASE_VERSION", description: "compile version:$env.PROP_NEXT_BUILD_NUMBER"
                    }
                }
            }
        }

        stage('Publish from ansible server') {
            agent {
                label 'ios-agent'
            }
            steps {
                withEnv(["HotfixVersion=$env.RELEASE_VERSIONCORE+$env.NEXT_BUILD_NUMBER",
                         "RootCredentialsId=$PROP_ROOT_RSA",
                         "IpaSize=$env.IPA_SIZE",
                         "BuildUser=$env.BUIlD_USER",
                         "JenkinsCredentialsId=$PROP_GIT_CREDENTIALS_ID",
                         "BuildEnviroment=$PROP_BUILD_ENVIRONMENT",
                         "DownloadLink=$PROP_DOWNLOAD_LINK"
                ]) {
                    dir('project') {
                        withCredentials([sshUserPrivateKey(credentialsId: "$RootCredentialsId", keyFileVariable: 'keyFile', passphraseVariable: '', usernameVariable: 'username')]) {
                            script {
                                def remote = [:]
                                remote.name = 'mis ansible'
                                remote.host = 'mis-ansible-app-01p'
                                remote.user = 'root'
                                remote.identityFile = keyFile
                                remote.allowAnyHosts = true

                                sshCommand remote: remote, command: """
                                    ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_TIMEOUT=30; ansible-playbook -v /data-disk/brand-team/deploy-kto-ios-ipa.yml -u root --extra-vars "apkFeed=kto-asia tag=$HotfixVersion ipa_size=$IpaSize download_url=$DownloadLink" -i /data-disk/brand-team/qat3.ini
                                """
                            }
                        }
                        sshagent(["$JenkinsCredentialsId"]) {
                                sh script:"""
                                    git config user.name "devops"
                                    git tag -f -a -m "release $BuildEnviroment version from ${env.BUIlD_USER}" $ReleaseTag
                                    git push $PROP_GIT_REPO_URL $ReleaseTag
                                """ , returnStatus:true
                            }
                    }
                }
            }
        }

        stage('Update jira issues') {
            //Update jira issue have been deploted to qat3
            steps {
                withEnv(["Enviroment=${PROP_BUILD_ENVIRONMENT.toLowerCase()}",
                         "NewVersion=ios-$env.VERSION_CORE"
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

        stage('QAT3 Notification') {
            steps {
                script {
                    withEnv(["ReleaseTag=$env.RELEASE_TAG",
                             "BuildEnvrioment=${PROP_BUILD_ENVIRONMENT.toLowerCase()}",
                             "ReleaseVersion=$env.RELEASE_VERSION",
                             "ReleaseVersionCore=$env.RELEASE_VERSIONCORE",
                             "TeamsToken=$PROP_TEAMS_NOTIFICATION",
                             "DownLoadLink=$PROP_DOWNLOAD_LINK"
                    ]) {
                        office365ConnectorSend webhookUrl: "$TeamsToken",
                                message: ">**[IOS][Hotfix] [KTO Asia]** has been deployed to $BuildEnvrioment</br>version : **[$ReleaseTag]($JENKINS_PROGET_HOME/feeds/app/ios/kto-asia/$ReleaseVersion/files)**",
                                factDefinitions: [[name: 'TestFlight Link', template: "<a href=\"$DownLoadLink\">Download Page</a>"],
                                                  [name: 'Related Issues', template: "<a href=\"https://jira.higgstar.com/issues/?jql=project = APP AND labels = ios-$ReleaseVersionCore-$BuildEnvrioment\">Jira Issues</a>"]]
                    }
                }
            }
        }
    }
}
