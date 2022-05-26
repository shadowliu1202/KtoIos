library 'utils'
pipeline {
    agent {
        label 'master'
    }
    options {
        ansiColor('gnome-terminal')
    }

    stages {
        stage('init workspace') {
            //取得Production環境的線上版本，
            steps {
                cleanWs()
                echo sh(script: 'env|sort', returnStdout: true)
                script {
                    currentBuild.displayName = "[$env.BUILD_ENVIRONMENT] $params.RELEASE_TAG"
                    env.ONLINE_TAG = ansible.getIosOnlineVersion('pro').trim()
                    String[] result =  params.RELEASE_TAG.trim().split('\\+')
                    String[] core =  result[0].split('-')
                    env.VERSION_CORE = core[0]
                    env.PRE_RELEASE = core[1]
                    if (result.length == 1) {
                        env.NEXT_BUILD_NUMBER = 1
                    } else {
                        env.NEXT_BUILD_NUMBER = result[1]
                    }
                    dir('project') {
                        iosutils.checkoutTagOnIosKtoAsia(params.RELEASE_TAG, env.ONLINE_TAG)
                    }
                }
            }
        }

        stage('Publish APK to Ansible') {
            steps {
                script {
                    dir('project') {
                        downloadProgetPackage downloadFolder: "${WORKSPACE}/project", downloadFormat: 'zip', feedName: 'app', groupName: 'ios', packageName: 'kto-asia', version: "$env.VERSION_CORE-$env.PRE_RELEASE"
                        unzip dir: '', glob: 'output/*ios-staging.ipa', zipFile: "kto-asia-${env.VERSION_CORE}-${env.PRE_RELEASE}.zip"
                        def size = sh(script:"du -s -k output/ktobet-asia-ios-${env.BUILD_ENVIRONMENT_FULL}.ipa | awk '{printf \"%.2f\\n\", \$1/1024}'", returnStdout: true).trim()
                        echo "Get Ipa Size = $size"
                        ansible.publishIosOnlineVersion(env.VERSION_CORE, env.PRE_RELEASE, env.NEXT_BUILD_NUMBER, env.IOS_DOWNLOAD_URL, size)
                    }
                }
            }
        }

        stage('Update jira issues') {
            steps {
                script {
                    def issueList = []
                    issueList.addAll(jira.getChangeLogIssues())
                    issueList.addAll(jira.getChangeIssues())
                    echo "Get Jira Issues: $issueList"
                    jira.transferIssues(issueList, env.JIRA_TRANSITION, null, "ios-$env.VERSION_CORE")
                }
            }
        }

        stage('Publish Notification') {
            steps {
                script {
                    teams.notifyRelease(env.TEAMS_NOTIFICATION, env.VERSION_CORE, env.PRE_RELEASE, env.NEXT_BUILD_NUMBER, env.BUILD_ENVIRONMENT, env.API_HOST)
                }
            }
        }

        stage('trigger build for qat3 enviroment') {
            steps {
                script {
                    if (env.PRE_RELEASE == 'release') {
                        build job: 'qat3_publish', parameters: [string(name: 'HOTFIX_BRNACH', value: 'master'), string(name: 'UP_STREAM_TAG', value: params.RELEASE_TAG)] , wait: false , propagate : false
                    }
                }
            }
        }
    }
}
 