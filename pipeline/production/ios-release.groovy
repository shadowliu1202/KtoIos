library 'utils'
pipeline {
    agent {
        label 'master'
    }
    options {
        ansiColor('gnome-terminal')
    }

    stages {
        stage('Checkout Online Version') {
            steps {
                cleanWs()
                script {
                    env.ONLINE_TAG = ansible.getIosOnlineVersion(env.BUILD_ENVIRONMENT.toLowerCase()).trim()
                    String[] result =  env.ONLINE_TAG.split('\\+')
                    String[] core =  env.ONLINE_TAG.split('-')
                    if (result.length == 1) {
                        env.ONLINE_VERSION_CORE = core[0]
                        env.ONLINE_BUILD_NUMBER = 1
                    } else {
                        env.ONLINE_VERSION_CORE = core[0]
                        env.ONLINE_BUILD_NUMBER = result[1]
                    }
                }
                echo sh(script: 'env|sort', returnStdout: true)
            }
        }
        stage('Define release version') {
            //使用選擇的版本的建置號作為建置號，跟建置要發布的TAG
            steps {
                script {
                        def splitTag = params.PARAMS_SELECT_TAG.split('\\+')
                        env.VERSION_CORE = splitTag[0].split('-')[0]
                        if (splitTag.length == 1) {
                            env.NEXT_BUILD_NUMBER = 1
                        }else {
                            env.NEXT_BUILD_NUMBER = splitTag[1]
                        }
                        env.RELEASE_TAG = version.getReleaseTag(env.VERSION_CORE, env.PRE_RELEASE, env.NEXT_BUILD_NUMBER)
                        currentBuild.displayName = "[$env.BUILD_ENVIRONMENT] $env.RELEASE_TAG"
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
                    script {
                        iosutils.checkoutTagOnIosKtoAsia(params.PARAMS_SELECT_TAG, env.ONLINE_TAG)
                        iosutils.buildProject(env.VERSION_CORE, env.PRE_RELEASE, env.NEXT_BUILD_NUMBER, env.FASTLANE_JOB)
                        iosutils.updateTestFlight(env.VERSION_CORE, env.NEXT_BUILD_NUMBER, env.PRE_RELEASE)
                        version.setIosTag(env.RELEASE_VERSIONCORE, env.PRERELEASE, env.NEXT_BUILD_NUMBER, env.BUILD_ENVIRONMENT.toLowerCase())
                    }
                }
            }
        }

        stage('Update jira issues') {
            //建置專案
            //建立Jira Release Version, 如果已經存在就忽略
            //更新所有改變的Jira Issue的 環境Label
            steps {
                script {
                    def issueList = []
                    issueList.addAll(jira.getChangeLogIssues())
                    issueList.addAll(jira.getChangeIssues())
                    echo "Get Jira Issues: $issueList"
                    jira.transferIssues(issueList, null, "ios-${env.VERSION_CORE}-${env.BUILD_ENVIRONMENT.toLowerCase()}")
                }
            }
        }

        stage('Release Notification') {
            steps {
                script {
                    teams.notifyRelease(env.TEAMS_NOTIFICATION_TOKEN, env.VERSION_CORE, env.PRE_RELEASE, env.NEXT_BUILD_NUMBER, env.ONLINE_TAG, env.BUILD_ENVIRONMENT, env.API_HOST,env.TESTFLIGHT_URL)
                }
            }
        }

        stage('Auto Trigger publish') {
            when {
                expression { params.AUTO_PUBLISH != null && params.AUTO_PUBLISH == true }
            }
            steps {
                build wait: false, job: env.PUBLISH_JOB, parameters: [text(name: 'PROP_RELEASE_TAG', value: env.RELEASE_TAG)]
            }
        }
    }
}
