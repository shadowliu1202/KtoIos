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
        PROP_AGENT_KEYCHAIN_PASSWORD = 'ios_agent_keychain_password'
        PROP_BUILD_ENVIRONMENT = 'Qat3'
        PROP_BUILD_BRANCH = "$params.HOTFIX_BRNACH".replace('refs/heads/', '')
        PROP_DOWNLOAD_LINK = "$env.DOWNLOAD_URL"
        PROP_TEAMS_NOTIFICATION = "$params.TEAMS_NOTIFICATION"
    }

    stages {
        stage('Diff changes') {
            //取得Production環境的線上版本，
            steps {
                echo sh(script: 'env|sort', returnStdout: true)
                cleanWs()
                script {
                    env.PRODUCTION_ONLINE_TAG = ansible.getProductionTag()
                    String[] result =  env.PRODUCTION_ONLINE_TAG.trim().split('\\+')
                    String[] core =  env.PRODUCTION_ONLINE_TAG.trim().split('-')
                    if (result.length == 1) {
                        env.PRODUCT_VERSION_CORE = core[0]
                        env.PRODUCTION_ONLINE_BUILDNUMBER = 1
                    } else {
                        env.PRODUCT_VERSION_CORE = core[0]
                        env.PRODUCTION_ONLINE_BUILDNUMBER = result[1]
                    }
                }
            }
        }

        stage('Release QAT3 project') {
            agent {
                label 'ios-agent'
            }
            steps {
                cleanWs()
                dir('project') {
                    script {
                        env.RELEASE_VERSIONCORE = "${PROP_BUILD_BRANCH.split('-')[0]}"
                        if (env.RELEASE_VERSIONCORE != env.PRODUCT_VERSION_CORE) error "release hotfix version core(${env.RELEASE_VERSIONCORE}) should the same as prouction version(${env.PRODUCT_VERSION_CORE})"
                        Date date = new Date()
                        env.PRERELEASE = "hotfix.${date.format('MMddHHmm')}"
                        env.RELEASE_VERSION = "$env.RELEASE_VERSIONCORE-$env.PRERELEASE"
                        iosutils.checkoutIosKtoAsia(PROP_BUILD_BRANCH,env.PRODUCTION_ONLINE_TAG)
                        def nextBuildNumber = iosutils.getNextBuildNumber(env.PRODUCTION_ONLINE_TAG, env.RELEASE_VERSIONCORE, 'hotfix')
                        env.NEXT_BUILD_NUMBER = nextBuildNumber
                        currentBuild.displayName = "[Qat3] $env.RELEASE_VERSIONCORE-$env.PRERELEASE+$env.NEXT_BUILD_NUMBER"
                        iosutils.buildQat3Project(PROP_BUILD_BRANCH,env.PRODUCTION_ONLINE_TAG,env.RELEASE_VERSIONCORE,env.PRERELEASE)
                    }
                    // withEnv(["AppleApiKey=$PROP_APPLE_STORE_API_KEY",
                    //          "BuildRepo=$PROP_GIT_REPO_URL",
                    //          "GitCredentialId=$PROP_GIT_CREDENTIALS_ID",
                    //          'MATCH_PASSWORD=password',
                    //          "BuildBranch=$PROP_BUILD_BRANCH",
                    //          "OnlineTag=$env.PRODUCTION_ONLINE_TAG",
                    //          "BuildEnviroment=$PROP_BUILD_ENVIRONMENT",
                    //          "KEY_ID=$PROP_APPLE_STORE_KEY_ID",
                    //          "VersionCode=$env.PRODUCT_VERSION_CORE"

                    // ]) {
                    //     checkout([$class           : 'GitSCM',
                    //               branches         : [[name: "refs/heads/$BuildBranch"]],
                    //               browser          : [$class: 'GitLab', repoUrl: "$BuildRepo", version: '14.4'],
                    //               extensions       : [[$class: 'ChangelogToBranch', options: [compareRemote: 'refs', compareTarget: "tags/$OnlineTag"]],
                    //                                   [$class: 'AuthorInChangelog'],
                    //                                   [$class: 'BuildSingleRevisionOnly']],
                    //               userRemoteConfigs: [[credentialsId: "$GitCredentialId",
                    //                                    refspec      : "+refs/heads/$BuildBranch:refs/remotes/origin/$BuildBranch +refs/heads/tags/*:refs/remotes/origin/tags/*",
                    //                                    url          : "$BuildRepo"]]
                    //     ])
                    //     withCredentials([file(credentialsId: "$AppleApiKey", variable: 'API_KEY'),
                    //                     string(credentialsId: 'ios_agent_keychain_password', variable: 'KEYCHAIN_PASSWORD')
                    //     ]) {
                    //         script {
                    //             env.RELEASE_VERSIONCORE = "${BuildBranch.split('-')[0]}"
                    //             if (env.RELEASE_VERSIONCORE != VersionCode) error "hotfix version(${env.RELEASE_VERSIONCORE}) should the same as prouction version($VersionCode)"
                    //             Date date = new Date()
                    //             env.PRERELEASE = "hotfix.${date.format('MMddHHmm')}"
                    //             env.RELEASE_VERSION = "$VersionCode-$env.PRERELEASE"

                    //             string onlineBuildVersion = OnlineTag.trim().split('\\+')
                    //             int lastBuildNumber = 1
                    //             if (onlineBuildVersion.length == 1) {
                    //                echo "$OnlineTag has no build number"
                    //             } else {
                    //                 lastBuildNumber = (onlineBuildVersion[1] as int)
                    //             }
                    //             int testFlightBuildNumber = 0
                    //             withEnv(["KEY_ID=$PROP_APPLE_STORE_KEY_ID"]) {
                    //                 def statusCode  = sh script:"fastlane getNextTestflightBuildNumber releaseTarget:hotfix targetVersion:$VersionCode", returnStatus:true
                    //                 if (statusCode == 0) {
                    //                     testFlightBuildNumber = readFile('fastlane/buildNumber').trim() as int
                    //                 }
                    //             }

                    //             env.NEXT_BUILD_NUMBER = Math.max(lastBuildNumber, testFlightBuildNumber) + 1
                    //             env.RELEASE_TAG = "$env.RELEASE_VERSION+$env.NEXT_BUILD_NUMBER"
                    //             currentBuild.displayName = "[$BuildEnviroment] $env.RELEASE_TAG"
                    //         }
                    //         sh """
                    //             pod install --repo-update
                    //             fastlane buildQat3 buildVersion:$env.NEXT_BUILD_NUMBER appVersion:$env.RELEASE_VERSIONCORE
                    //         """
                    //         script {
                    //             env.IPA_SIZE = sh(script:"du -s -k output/ktobet-asia-ios-${BuildEnviroment.toLowerCase()}.ipa | awk '{printf \"%.2f\\n\", \$1/1024}'", returnStdout: true).trim()
                    //             echo "Get Ipa Size = $IPA_SIZE"
                    //         }
                    //     }
                    //     uploadProgetPackage artifacts: 'output/*.ipa', feedName: 'app', groupName: 'ios', packageName: 'kto-asia', version: "$env.RELEASE_VERSION", description: "compile version:$env.PROP_NEXT_BUILD_NUMBER"
                    // }
                }
            }
        }

        stage('Publish from ansible server') {
            agent {
                label 'ios-agent'
            }
            steps {
                dir('project') {
                        script {
                            def size = sh(script:"du -s -k output/ktobet-asia-ios-qat3.ipa | awk '{printf \"%.2f\\n\", \$1/1024}'", returnStdout: true).trim()
                            echo "Get Ipa Size = $size"
                            ansible.publishIosVersionToQat(env.PRERELEASE, env.RELEASE_VERSIONCORE, env.NEXT_BUILD_NUMBER, PROP_DOWNLOAD_LINK, size, PROP_BUILD_ENVIRONMENT)
                        }
                }
            }
        }

        stage('Update jira issues') {
            //Update jira issue have been deploted to qat3
            steps {
                script {
                        def issueList = []
                        issueList.addAll(jira.getChangeLogIssues())
                        issueList.addAll(jira.getChangeIssues())
                        echo "Get Jira Issues: $issueList"
                        jira.transferIssues(issueList, 'SEEKING APPROVAL', "ios-$env.RELEASE_VERSIONCORE-qat3", "ios-$env.RELEASE_VERSIONCORE-$env.PRERELEASE")
                }
            }
        }

        stage('QAT3 Notification') {
            steps {
                script {
                    teams.notifyQat3(PROP_TEAMS_NOTIFICATION, env.RELEASE_VERSIONCORE, env.PRERELEASE, env.NEXT_BUILD_NUMBER, env.PRODUCTION_ONLINE_BUILDNUMBER)
                }
            }
        }
    }
}
