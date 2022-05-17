pipeline {
    agent {
        label 'master'
    }
    options {
        ansiColor('gnome-terminal')
    }
    environment {
        //ios-publish
        PROP_SYSADMIN_RSA = '0dd067b6-8bd0-4c0a-9cb7-fb374ed7084e'
        PROP_GIT_CREDENTIALS_ID = '28ef89bf-70a2-475d-b5e0-a1ea12a8fcdb'
        PROP_GIT_REPO_URL = 'git@gitlab.higgstar.com:mobile/ktobet-asia-ios.git'
        PROP_PRE_REALEASE = "$env.PRE_RELEASE" // <= setup from upstream
        PROP_DOWNLOAD_LINK = "$env.IOS_DOWNLOAD_URL" // <= setup from upstream
        PROP_TESTFLIGHT_LINK = "$env.IOS_TESTFLIGHT_URL" // <= setup from upstream
        PROP_REMOTE_ANS_HOST = "$env.REMOTE_ANS_HOST" // <= setup from upstream
        PROP_BUILD_ENVIRONMENT = "$env.BUILD_ENVIRONMENT" // <= setup from upstream
        PROP_PUBLISH_TAG = "$env.PROP_RELEASE_TAG" // < = setup from upstream
        PROP_CURRENT_ONLINE_TAG = "$env.CURRENT_ONLINE_TAG" // < = setup from upstream
        PROP_TEAMS_NOTIFICATION = "$env.TEAMS_NOTIFICATION_TOKEN"
        PROP_VERSION_CORE = "${env.PROP_RELEASE_TAG.split('\\+')[0].split('-')[0]}"
        PROP_BUILD_ENVIRONMENT_FULL = "$env.BUILD_ENVIRONMENT_FULL"
        PROP_JIRA_TRANSITION = "$env.JIRA_TRANSITION"
    }

    stages {
        stage('Define Change Set') {
            //取得Production環境的線上版本，
            steps {
                echo sh(script: 'env|sort', returnStdout: true)
                cleanWs()
                script {
                    withEnv(["PublishTag=$PROP_PUBLISH_TAG",
                             "OnlineTag=$PROP_CURRENT_ONLINE_TAG",
                             "CredentialsId=$PROP_GIT_CREDENTIALS_ID",
                             "Repo=$PROP_GIT_REPO_URL",
                             "BuildEnviroment=$PROP_BUILD_ENVIRONMENT",
                            "SysAdmin=$PROP_SYSADMIN_RSA",
                            "AnsibleServer=$PROP_REMOTE_ANS_HOST",
                    ]) {
                        checkout([$class: 'GitSCM',
                                    branches: [[name: "refs/tags/$PublishTag"]],
                                    extensions: [[$class: 'ChangelogToBranch',
                                                options: [compareRemote: 'refs',
                                                compareTarget: "tags/$OnlineTag"]],
                                                [$class: 'BuildSingleRevisionOnly']],
                                    userRemoteConfigs: [[credentialsId: "$CredentialsId",
                                                        refspec: '+refs/heads/master:refs/remotes/origin/master +refs/heads/tags/*:refs/remotes/origin/tags/*',
                                                        url: "$Repo"]]])
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
                                    if (commandResult.empty) {
                                        env.PRODUCTION_ONLINE_TAG = '0.0.1'
                                    } else {
                                        String[] result = commandResult.trim().split('\\+')
                                        if (result.length == 1) {
                                            env.PRODUCTION_ONLINE_TAG = "${result[0]}-release"
                                        } else {
                                            env.PRODUCTION_ONLINE_TAG = "${result[0]}-release+${result[1]}"
                                        }
                                    }
                                    echo "production version = $PRODUCTION_ONLINE_TAG"
                                    currentBuild.displayName = "[$BuildEnviroment] $PublishTag"
                                }
                        }
                    }
                }
            }
        }

        stage('Get IPA Size') {
            //取得檔案的size
            steps{
                withEnv(["PublishTag=$PROP_PUBLISH_TAG",
                         "AnsibleServer=$PROP_REMOTE_ANS_HOST",
                          "BuildEnviromentFull=$PROP_BUILD_ENVIRONMENT_FULL"
                ]){                    
                    script {
                        String version  = PublishTag.split('\\+')[0]
                        downloadProgetPackage downloadFolder: "$WORKSPACE", downloadFormat: 'unpack', feedName: 'app', groupName: 'ios', packageName: 'kto-asia', version: "$version"
                        env.IPA_SIZE = sh(script:"du -s -k output/ktobet-asia-ios-${BuildEnviromentFull}.ipa | awk '{printf \"%.2f\\n\", \$1/1024}'", returnStdout: true).trim()
                        echo "Get Ipa Size = $env.IPA_SIZE"
                    }
                }
            }
        }

        stage('Publish APK to Ansible') {
            steps {
                withEnv(["PublishTag=$PROP_PUBLISH_TAG",
                         "IpaSize=$env.IPA_SIZE",
                         "AnsibleServer=$PROP_REMOTE_ANS_HOST",
                         "DownloadLink=$PROP_DOWNLOAD_LINK",
                         "SysAdmin=$PROP_SYSADMIN_RSA"
                ]) {
                    withCredentials([sshUserPrivateKey(credentialsId: "$SysAdmin", keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'user')]) {
                        script {
                            def remote = [:]
                            remote.name = 'mis ansible'
                            remote.host = "$AnsibleServer"
                            remote.user = user
                            remote.identityFile = identity
                            remote.allowAnyHosts = true
                        sshCommand remote: remote, command: """
                            ansible-playbook -v /data-disk/brand-deployment-document/playbooks/deploy-kto-ios-ipa.yml --extra-vars "apkFeed=kto-asia tag=$PublishTag ipa_size=$IpaSize download_url=$DownloadLink"
                        """
                        }
                    }
                }
            }
        }

        stage('Update jira issues') {
            steps {
                withEnv(["ReleaseVersionCore=$PROP_VERSION_CORE",
                         "ProductionOnlineTag=$PRODUCTION_ONLINE_TAG",
                         "Enviroment=${PROP_BUILD_ENVIRONMENT.toLowerCase()}",
                         "Transition=$PROP_JIRA_TRANSITION"
                ]) {
                    script {
                        def issueKeys = jiraIssueSelector(issueSelector: [$class: 'DefaultIssueSelector'])
                        for (issue in issueKeys) {
                            def jiraTransitions = jiraGetIssueTransitions failOnError: false, idOrKey: "$issue", site: 'Higgs-Jira'
                            def data = jiraTransitions.data
                            if (data != null && data.transitions != null) {
                                for (transition in data.transitions) {
                                    if (transition.name == "$Transition") {
                                        echo "transfer $issue with $transition"
                                        def transitionInput = [transition: [id: "$transition.id"]]
                                        jiraTransitionIssue failOnError: false, site: 'Higgs-Jira', input:transitionInput, idOrKey: "$issue"
                                        break
                                    }
                                }
                            }
                        }
                        if (Enviroment == 'pro') {
                            def releaseVersion = [ name: "ios-$ReleaseVersionCore", released: true, project: 'APP' ]
                            jiraNewVersion failOnError: false, version: releaseVersion, site: 'Higgs-Jira'
                        }
                    }
                }
            }
        }

        stage('Publish Notification') {
            steps {
                script {
                    withEnv(["PublishTag=$PROP_PUBLISH_TAG",
                             "OnlineTag=$PROP_CURRENT_ONLINE_TAG",
                             "Enviroment=${PROP_BUILD_ENVIRONMENT.toLowerCase()}",
                             "Version=$PROP_VERSION_CORE",
                             "TeamsToken=$PROP_TEAMS_NOTIFICATION",
                             "DownloadLink=$PROP_DOWNLOAD_LINK",
                             "UpdateIssues=https://jira.higgstar.com/issues/?jql=project = APP AND fixVersion = ios-$PROP_VERSION_CORE",
                    ]) {
                        String path = PublishTag.split('\\+')[0]
                        String publish = PublishTag.split('-')[0]
                        String online = OnlineTag.split('-')[0]
                        echo "detail $path $publish $online"
                        office365ConnectorSend webhookUrl: "$TeamsToken",
                                message: ">**[IOS] [KTO Asia]** has been published to $Enviroment</br>version : **[$PublishTag]($JENKINS_PROGET_HOME/feeds/app/ios/kto-asia/${path}/files)**",
                                factDefinitions: [[name: 'Testflight Page', template: "<a href=\"$DownloadLink\">link</a>"],
                                                  [name: 'Update Issues', template: "$online->$publish (<a href=\"$UpdateIssues\">issues</a>)"]]
                    }
                }
            }
        }
    }
}
