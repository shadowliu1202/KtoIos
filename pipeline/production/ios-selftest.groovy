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
                    currentBuild.displayName = "[Pro][SelfTest] $params.RELEASE_TAG"
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
                        iosutils.checkoutTagOnIosKtoAsia(params.RELEASE_TAG, env.ONLINE_TAG)
                        iosutils.buildProject(env.VERSION_CORE, env.PRE_RELEASE, env.NEXT_BUILD_NUMBER, 'buildIpaProduction')
                        iosutils.updateTestFlight(env.VERSION_CORE, env.NEXT_BUILD_NUMBER, 'selftest')
                        iosutils.updateTestFlight(env.VERSION_CORE, env.NEXT_BUILD_NUMBER, 'backup')
                        version.setIosTag(env.RELEASE_VERSIONCORE, env.PRERELEASE, env.NEXT_BUILD_NUMBER, env.BUILD_ENVIRONMENT.toLowerCase())
                    }
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
    }
}

