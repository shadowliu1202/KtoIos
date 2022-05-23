library 'utils'
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
        stage('Define release version') {
            //workaround currentVersion of plug-in need jenkins version after 2.234
            steps {
                cleanWs()
                script {
                    def lastTag =  ansible.qatTag
                    echo "Get Last Tag $lastTag"
                    iosutils.checkoutIosKtoAsia('master', lastTag)
                    env.PROP_CURRENT_TAG = lastTag
                    env.PROP_RELEASE_VERSION = nextVersion(preRelease: 'dev')
                    env.PROP_RELEASE_VERSIONCORE = PROP_RELEASE_VERSION.split('-')[0]
                    echo "Update from $env.PROP_CURRENT_TAG to $env.PROP_RELEASE_VERSION"
                }
                echo sh(script: 'env|sort', returnStdout: true)
            }
        }

        // stage('Build QAT Project') {
        //     agent {
        //         label 'ios-agent'
        //     }
        //     steps {
        //         cleanWs()
        //         dir('project') {
        //             script {
        //                 iosutils.checkoutIosKtoAsia(env.BUILD_BRANCH)
        //                 def nextBuildNumber = iosutils.getTestFlightBuildNumber(env.PROP_RELEASE_VERSIONCORE, 'dev') + 1
        //                 env.NEXT_BUILD_NUMBER = nextBuildNumber
        //                 currentBuild.displayName = "[Qat1] $env.PROP_RELEASE_VERSIONCORE-dev+$env.NEXT_BUILD_NUMBER"
        //                 iosutils.buildProject(env.RELEASE_VERSIONCORE, env.PRERELEASE, nextBuildNumber, 'uploadToTestflight')
        //             }
        //         }
        //     }
        // }

        // stage('Publish APK to Ansible') {
        //     agent {
        //         label 'ios-agent'
        //     }
        //     steps {
        //         script {
        //             def size = sh(script:"du -s -k output/ktobet-asia-ios-qat3.ipa | awk '{printf \"%.2f\\n\", \$1/1024}'", returnStdout: true).trim()
        //             echo "Get Ipa Size = $size"
        //             ansible.publishIosVersionToQat(env.PRERELEASE, env.RELEASE_VERSIONCORE, env.NEXT_BUILD_NUMBER, PROP_DOWNLOAD_LINK, size, 'qat1')
        //         }
        //     }
        // }

        // stage('Trigger staging publish') {
        //     when {
        //         expression { INCLUDE_STAGING == true }
        //     }
        //     steps {
        //         build wait: false, job: "$PROP_STAGING_JOB", parameters: [text(name: 'ReleaseTag', value: "${env.PROP_RELEASE_TAG}")]
        //     }
        // }

        // stage('Update jira issues') {
        //     //Update jira issue have been deploted to qat3
        //     steps {
        //         withEnv(["Enviroment=${PROP_BUILD_ENVIRONMENT.toLowerCase()}",
        //                  "NewVersion=ios-$PROP_RELEASE_VERSIONCORE",
        //                  'Transition=ReleaseToReporter'
        //         ]) {
        //             script {
        //                 def issueList = []
        //                 issueList.addAll(jira.getChangeLogIssues())
        //                 issueList.addAll(jira.getChangeIssues())
        //                 echo "Get Jira Issues: $issueList"
        //                 jira.transferIssues(issueList, Transition, "$NewVersion-$Enviroment")
        //             }
        //         }
        //     }
        // }

        // stage('Notification') {
        //     steps {
        //         script {
        //             withEnv(["ReleaseTag=$env.PROP_RELEASE_TAG",
        //                      "OnlineTag=$env.PROP_CURRENT_TAG",
        //                      "BuildEnvrioment=${PROP_BUILD_ENVIRONMENT.toLowerCase()}",
        //                      "ReleaseVersion=$PROP_RELEASE_VERSION",
        //                      "ReleaseVersionCore=$PROP_RELEASE_VERSIONCORE",
        //                      "TeamsToken=$PROP_TEAMS_NOTIFICATION",
        //                      "UpdateIssues=https://jira.higgstar.com/issues/?jql=project = APP AND labels = ios-$PROP_RELEASE_VERSIONCORE-${PROP_BUILD_ENVIRONMENT.toLowerCase()}"
        //             ]) {
        //                 String publish = ReleaseTag.split('-')[0]
        //                 String online = OnlineTag.split('-')[0]
        //                 office365ConnectorSend webhookUrl: "$TeamsToken",
        //                         message: ">**[Android] [KTO Asia]** has been deployed to $BuildEnvrioment</br>version : **[$ReleaseTag]($JENKINS_PROGET_HOME/feeds/app/ios/kto-asia/$ReleaseVersion/files)**",
        //                         factDefinitions: [[name: 'Download Page', template: '<a href="https://qat1-mobile.affclub.xyz/">Download Page</a>'],
        //                                           [name: 'Update Issues', template: "<a href=\"https://jira.higgstar.com/issues/?jql=project = APP AND labels = ios-$ReleaseVersionCore-$BuildEnvrioment\">Jira Issues</a>"],
        //                                           [name: 'Update Issues', template: "$online->$publish (<a href=\"$UpdateIssues\">issues</a>)"]]
        //             }
        //         }
        //     }
        // }
    }
}
