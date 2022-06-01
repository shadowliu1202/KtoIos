library 'utils'
pipeline {
    agent {
        label 'master'
    }
    options {
        ansiColor('gnome-terminal')
    }
    environment {
        PRE_RELEASE = 'dev'
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
                    //def lastTag = ansible.qatTag
                    def lastTag = "1.4.0-dev"
                    echo "Get Last Tag $lastTag"
                    iosutils.checkoutIosKtoAsia('master', lastTag)
                    env.CURRENT_TAG = lastTag
                    env.RELEASE_VERSION = nextVersion(preRelease: env.PRE_RELEASE)
                    env.RELEASE_VERSIONCORE = RELEASE_VERSION.split('-')[0]
                    echo "Update from $env.CURRENT_TAG to $env.RELEASE_VERSION"
                }
                echo sh(script: 'env|sort', returnStdout: true)
            }
        }

        stage('Build QAT Project') {
            agent {
                label 'ios-agent'
            }
            steps {
                cleanWs()
                dir('project') {
                    script {
                        iosutils.checkoutIosKtoAsia('master')
                        def nextBuildNumber = iosutils.getTestFlightBuildNumber(env.RELEASE_VERSIONCORE, env.PRE_RELEASE) + 1
                        env.NEXT_BUILD_NUMBER = nextBuildNumber
                        def tag = version.getReleaseTag(env.RELEASE_VERSIONCORE, env.PRE_RELEASE, nextBuildNumber)
                        currentBuild.displayName = "[Qat1] $tag"
                        iosutils.buildProject(env.RELEASE_VERSIONCORE, env.PRE_RELEASE, nextBuildNumber, 'uploadToTestflight')
                        def size = sh(script:"du -s -k output/ktobet-asia-ios-qat.ipa | awk '{printf \"%.2f\\n\", \$1/1024}'", returnStdout: true).trim()
                        echo "Get Ipa Size = $size"
                        ansible.publishIosVersionToQat(env.RELEASE_VERSIONCORE, env.PRE_RELEASE, env.NEXT_BUILD_NUMBER, env.IOS_DOWNLOAD_URL, size, 'qat1')
                        version.setIosTag( env.RELEASE_VERSIONCORE, env.PRE_RELEASE, env.NEXT_BUILD_NUMBER, 'qat1')
                    }
                }
            }
        }

        stage('Trigger staging publish') {
            when {
                expression { INCLUDE_STAGING == true }
            }
            steps {
                script {
                    def tag = getReleaseTag( env.RELEASE_VERSIONCORE, env.PRE_RELEASE, env.NEXT_BUILD_NUMBER)
                    build wait: false, job: 'stg_release', parameters: [text(name: 'ReleaseTag', value: tag)]
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
                    jira.transferIssues(issueList, 'ReleaseToReporter', "ios-${env.RELEASE_VERSIONCORE}-qat")
                }
            }
        }

        stage('Notification') {
            steps {
                script {
                    teams.notifyQat1(env.TEAMS_NOTIFICATION_TOKEN, env.RELEASE_VERSIONCORE, env.PRE_RELEASE, env.NEXT_BUILD_NUMBER, env.CURRENT_TAG)                }
            }
        }
    }
}

