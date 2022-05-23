library 'utils'
pipeline {
    agent {
        label 'master'
    }
    options {
        ansiColor('gnome-terminal')
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
                    def lastTag = ansible.qatTag
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

        stage('Build QAT Project') {
            agent {
                label 'ios-agent'
            }
            steps {
                cleanWs()
                dir('project') {
                    script {
                        iosutils.checkoutIosKtoAsia('master')
                        def nextBuildNumber = iosutils.getTestFlightBuildNumber(env.PROP_RELEASE_VERSIONCORE, 'dev') + 1
                        env.NEXT_BUILD_NUMBER = nextBuildNumber
                        currentBuild.displayName = "[Qat1] $env.PROP_RELEASE_VERSIONCORE-dev+$env.NEXT_BUILD_NUMBER"
                        iosutils.buildProject(env.RELEASE_VERSIONCORE, env.PRERELEASE, nextBuildNumber, 'uploadToTestflight')
                    }
                }
            }
        }

        stage('Publish APK to Ansible') {
            agent {
                label 'ios-agent'
            }
            steps {
                script {
                    def size = sh(script:"du -s -k output/ktobet-asia-ios-qat3.ipa | awk '{printf \"%.2f\\n\", \$1/1024}'", returnStdout: true).trim()
                    echo "Get Ipa Size = $size"
                    ansible.publishIosVersionToQat(env.PRERELEASE, env.RELEASE_VERSIONCORE, env.NEXT_BUILD_NUMBER, env.IOS_DOWNLOAD_URL, size, 'qat1')
                }
            }
        }

        stage('Trigger staging publish') {
            when {
                expression { INCLUDE_STAGING == true }
            }
            steps {
                script{
                    def tag = getReleaseTag( env.RELEASE_VERSIONCORE, env.PRERELEASE, env.NEXT_BUILD_NUMBER)
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
                    jira.transferIssues(issueList, 'ReleaseToReporter', "$ios-$PROP_RELEASE_VERSIONCORE-qat")
                }
            }
        }

        stage('Notification') {
            steps {
                script {
                    teams.notifyQat1(env.TEAMS_NOTIFICATION_TOKEN, env.RELEASE_VERSIONCORE, env.PRERELEASE, env.NEXT_BUILD_NUMBER, env.PROP_CURRENT_TAG)                }
            }
        }
    }
}

