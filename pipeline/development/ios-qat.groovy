@Library('utils') _
pipeline {
    agent {
        label 'master'
    }
    options {
        ansiColor('gnome-terminal')
    }
    environment {
        PROP_GIT_CREDENTIALS_ID = '28ef89bf-70a2-475d-b5e0-a1ea12a8fcdb'
        PROP_GIT_REPO_URL = 'git@gitlab.higgstar.com:mobile/ktobet-asia-ios.git'
        PROP_APPLE_STORE_API_KEY = '63f71ab5-5473-43ca-9191-b34cd19f1fa1'
        PROP_APPLE_STORE_KEY_ID = '2XHCS3W99M'
        PROP_ANSIABLE_SERVER = 'mis-ansible-app-01p'
        PROP_NGINX_STATIC_SERVER = '172.16.100.122'
        PROP_ROOT_RSA = '2cb1ac3a-2e81-474e-9846-25fad87697ef'
        PROP_BUILD_ENVIRONMENT = 'Qat'
        PROP_PRE_REALEASE = 'dev'
        PROP_STAGING_JOB = 'stg_release'
        PROP_AGENT_KEYCHAIN_PASSWORD = 'ios_agent_keychain_password'
        PROP_BUILD_BRANCH = "${env.BUILD_BRANCH}"
        PROP_DOWNLOAD_LINK = "${env.IOS_DOWNLOAD_URL}"
        PROP_TEAMS_NOTIFICATION = "${env.TEAMS_NOTIFICATION_TOKEN}"
    }
    parameters {
        booleanParam defaultValue: false, description: '連Staging一起release', name: 'INCLUDE_STAGING'
    }

    stages {
        stage('Init workspace') {
            steps {
                cleanWs()
                script {
                     env.PROP_CURRENT_TAG = sh(
                            script: """
                                git ls-remote --tags --sort="v:refname" git@gitlab.higgstar.com:mobile/ktobet-asia-ios.git | tail -n1 | sed 's/.*\\///; s/\\^{}//'
                            """,
                            returnStdout: true
                    ).trim()
                    echo "Compare latest version: $env.PROP_CURRENT_TAG"
                    echo sh(script: 'env|sort', returnStdout: true)
                }
            }
        }
        stage('Define release version') {
            //workaround currentVersion of plug-in need jenkins version after 2.234
            steps {
                script {
                    checkout([$class: 'GitSCM',
                                  branches: [[name: "refs/heads/$PROP_BUILD_BRANCH"]],
                                  extensions: [[$class: 'ChangelogToBranch',
                                               options: [compareRemote: 'refs',
                                               compareTarget: "tags/$PROP_CURRENT_TAG"]],
                                               [$class: 'BuildSingleRevisionOnly']],
                                  userRemoteConfigs: [[credentialsId: "$PROP_GIT_CREDENTIALS_ID",
                                                      refspec: "+refs/heads/$PROP_BUILD_BRANCH:refs/remotes/origin/$PROP_BUILD_BRANCH +refs/heads/tags/*:refs/remotes/origin/tags/*",
                                                      url: "$PROP_GIT_REPO_URL"]]])
                    echo "Project Current Version : ${currentVersion()}"
                    String createVersion = nextVersion(preRelease: 'dev')
                    env.PROP_RELEASE_VERSION = "$createVersion"
                    env.PROP_RELEASE_VERSIONCORE = PROP_RELEASE_VERSION.split('-')[0]
                }
            }
        }

        stage('Build QAT Project') {
            agent {
                label 'ios-agent'
            }
            steps {
                cleanWs()
                dir('project') {
                    withEnv(["ReleaseVersion=$PROP_RELEASE_VERSION",
                             "ReleaseVersionCore=$PROP_RELEASE_VERSIONCORE",
                             "AppleApiKey=$PROP_APPLE_STORE_API_KEY",
                             "BuildRepo=$PROP_GIT_REPO_URL",
                             "CurrentTag=$PROP_CURRENT_TAG",
                             "GitCredentialId=$PROP_GIT_CREDENTIALS_ID",
                             'MATCH_PASSWORD=password',
                             "PreRelease=$PROP_PRE_REALEASE",
                             "BuildBranch=$PROP_BUILD_BRANCH",
                             "BuildEnviroment=$PROP_BUILD_ENVIRONMENT",
                             "KEY_ID=$PROP_APPLE_STORE_KEY_ID"

                    ]) {
                        checkout([$class: 'GitSCM',
                                  branches: [[name: "refs/heads/$BuildBranch"]],
                                  extensions: [[$class: 'BuildSingleRevisionOnly']],
                                  userRemoteConfigs: [[credentialsId: "$GitCredentialId",
                                                      refspec: "+refs/heads/$BuildBranch:refs/remotes/origin/$BuildBranch +refs/heads/tags/*:refs/remotes/origin/tags/*",
                                                      url: "$BuildRepo"]]])
                        withCredentials([file(credentialsId: "$AppleApiKey", variable: 'API_KEY'),
                                        string(credentialsId: 'ios_agent_keychain_password', variable: 'KEYCHAIN_PASSWORD')
                        ]) {
                            sh "fastlane getNextTestflightBuildNumber releaseTarget:$PreRelease targetVersion:$ReleaseVersionCore"
                            script {
                                int lastBuildNumber = readFile('fastlane/buildNumber').trim() as int
                                env.PROP_NEXT_BUILD_NUMBER = lastBuildNumber + 1
                                if (env.PROP_NEXT_BUILD_NUMBER == 1) {
                                    env.PROP_RELEASE_TAG = "$ReleaseVersion"
                                } else {
                                    env.PROP_RELEASE_TAG = "$ReleaseVersion+${env.PROP_NEXT_BUILD_NUMBER}"
                                }
                                currentBuild.displayName = "[$PROP_BUILD_ENVIRONMENT] ${env.PROP_RELEASE_TAG}"
                            }

                            // sh """
                            //     pod install --repo-update
                            //     fastlane uploadToTestflight buildVersion:${env.PROP_NEXT_BUILD_NUMBER} appVersion:$ReleaseVersionCore
                            // """
                            // script {
                            //     env.IPA_SIZE = sh(script:"du -s -k output/ktobet-asia-ios-${BuildEnviroment}.ipa | awk '{printf \"%.2f\\n\", \$1/1024}'", returnStdout: true).trim()
                            //     echo "Get Ipa Size = $IPA_SIZE"
                            // }
                        }
                        //uploadProgetPackage artifacts: 'output/*.ipa', feedName: 'app', groupName: 'ios', packageName: 'kto-asia', version: "${env.PROP_RELEASE_TAG}", description: "compile version:${env.PROP_NEXT_BUILD_NUMBER}"
                    }
                }
            }
        }

        stage('Publish APK to Ansible') {
            steps {
                withEnv(["ReleaseTag=${env.PROP_RELEASE_TAG}",
                         "RootCredentialsId=$PROP_ROOT_RSA",
                         "IpaSize=${env.IPA_SIZE}",
                         "BuildUser=${env.BUIlD_USER}",
                         "JenkinsCredentialsId=$PROP_GIT_CREDENTIALS_ID",
                         "BuildEnviroment=$PROP_BUILD_ENVIRONMENT",
                         "DownloadLink=$PROP_DOWNLOAD_LINK"
                ]) {
                    withCredentials([sshUserPrivateKey(credentialsId: "$RootCredentialsId", keyFileVariable: 'keyFile', passphraseVariable: '', usernameVariable: 'username')]) {
                        script {
                            def remote = [:]
                            remote.name = 'mis ansible'
                            remote.host = "$PROP_ANSIABLE_SERVER"
                            remote.user = username
                            remote.identityFile = keyFile
                            remote.allowAnyHosts = true
                        // sshCommand remote: remote, command: """
                        //     ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_TIMEOUT=30; ansible-playbook -v /data-disk/brand-team/deploy-kto-ios-ipa.yml -u root --extra-vars "apkFeed=kto-asia tag=$ReleaseTag ipa_size=$IpaSize download_url=$PROP_DOWNLOAD_LINK" -i /data-disk/brand-team/qat1.ini
                        // """
                        }
                    }
                    // wrap([$class: 'BuildUser']) {
                    //     sshagent(["$JenkinsCredentialsId"]) {
                    //         sh """
                    //         git config user.name "devops"
                    //         git tag -f -a -m "release $BuildEnviroment version from ${env.BUIlD_USER}" $ReleaseTag
                    //         git push $PROP_GIT_REPO_URL $ReleaseTag
                    //     """
                    //     }
                    // }
                }
            }
        }

        stage('Trigger staging publish') {
            when {
                expression { INCLUDE_STAGING == true }
            }
            steps {
                build wait: false, job: "$PROP_STAGING_JOB", parameters: [text(name: 'ReleaseTag', value: "${env.PROP_RELEASE_TAG}")]
            }
        }

        stage('Update jira issues') {
            //Update jira issue have been deploted to qat3
            steps {
                withEnv(["Enviroment=${PROP_BUILD_ENVIRONMENT.toLowerCase()}",
                         "NewVersion=ios-$PROP_RELEASE_VERSIONCORE",
                         'Transition=ReleaseToReporter'
                ]) {
                    script {
                        def issueList = []
                        issueList.addAll(jira.getChangeLogIssues())
                        issueList.addAll(jira.getChangeIssues())
                        echo "Get Jira Issues: $issueList"
                        jira.updateIssues(issueList,Transition,"$NewVersion-$Enviroment")
                    }
                }
            }
        }

        stage('Notification') {
            steps {
                script {
                    withEnv(["ReleaseTag=$env.PROP_RELEASE_TAG",
                             "OnlineTag=$env.PROP_CURRENT_TAG",
                             "BuildEnvrioment=${PROP_BUILD_ENVIRONMENT.toLowerCase()}",
                             "ReleaseVersion=$PROP_RELEASE_VERSION",
                             "ReleaseVersionCore=$PROP_RELEASE_VERSIONCORE",
                             "TeamsToken=$PROP_TEAMS_NOTIFICATION",
                             "UpdateIssues=https://jira.higgstar.com/issues/?jql=project = APP AND labels = ios-$PROP_RELEASE_VERSIONCORE-${PROP_BUILD_ENVIRONMENT.toLowerCase()}"
                    ]) {
                        String publish = ReleaseTag.split('-')[0]
                        String online = OnlineTag.split('-')[0]
                        office365ConnectorSend webhookUrl: "$TeamsToken",
                                message: ">**[Android] [KTO Asia]** has been deployed to $BuildEnvrioment</br>version : **[$ReleaseTag]($JENKINS_PROGET_HOME/feeds/app/ios/kto-asia/$ReleaseVersion/files)**",
                                factDefinitions: [[name: 'Download Page', template: '<a href="https://qat1-mobile.affclub.xyz/">Download Page</a>'],
                                                  [name: 'Update Issues', template: "<a href=\"https://jira.higgstar.com/issues/?jql=project = APP AND labels = ios-$ReleaseVersionCore-$BuildEnvrioment\">Jira Issues</a>"],
                                                  [name: 'Update Issues', template: "$online->$publish (<a href=\"$UpdateIssues\">issues</a>)"]]
                    }
                }
            }
        }
    }
}

def getChangeLogIssues() {
    def issueList = []
    def issueKeys = jiraIssueSelector(issueSelector: [$class: 'DefaultIssueSelector'])
    for (issue in issueKeys) {
        issueList.add(issue)
    }
    return issueList.toSorted()
}

@NonCPS
def getChangeIssues() {
    def issueList = []
    def changeLogSets = currentBuild.changeSets
    for (int i = 0; i < changeLogSets.size(); i++) {
        def entries = changeLogSets[i].items
        for (int j = 0; j < entries.length; j++) {
            issueList.addAll(entries[j].comment.findAll('APP-\\d+'))
        }
    }
    return issueList.toSorted()
}

def updateIssues(jiraIssues = []) {
    def updateIssue = [fields: [labels: ["$NewVersion-$Enviroment"]]]
    for (issue in jiraIssues) {
        jiraEditIssue failOnError: false, site: 'Higgs-Jira', idOrKey: "$issue", issue: updateIssue
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
}
