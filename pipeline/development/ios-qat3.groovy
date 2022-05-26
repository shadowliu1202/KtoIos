library 'utils'
pipeline {
    agent {
        label 'master'
    }
    options {
        ansiColor('gnome-terminal')
    }
    parameters{
         string(name: 'UP_STREAM_TAG', defaultValue: '', description: 'tag from upstream')
    }
    environment {
        PROP_BUILD_BRANCH = "$params.HOTFIX_BRNACH".replace('refs/heads/', '')
        PROP_DOWNLOAD_LINK = "$env.DOWNLOAD_URL"
        PROP_TEAMS_NOTIFICATION = "$params.TEAMS_NOTIFICATION"
        UP_STREAM_TAG = ''
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
                        iosutils.checkoutIosKtoAsia(PROP_BUILD_BRANCH, env.PRODUCTION_ONLINE_TAG)
                        if (params.HOTFIX_BRNACH.toString() != 'master') {
                            env.VERSION_CORE = PROP_BUILD_BRANCH.split('-')[0]
                            Date date = new Date()
                            env.PRE_RELEASE = "hotfix.${date.format('MMddHHmm')}"
                            env.NEXT_BUILD_NUMBER  = iosutils.getNextBuildNumber(env.PRODUCTION_ONLINE_TAG, env.VERSION_CORE, 'hotfix')
                        }else {
                            echo "trigger from upstream : $params.UP_STREAM_TAG"
                            String[] result =  params.UP_STREAM_TAG.trim().split('\\+')
                            String[] core = result[0].trim().split('-')
                            env.VERSION_CORE = core[0]
                            env.PRE_RELEASE = 'hotfix'
                            if (result.length == 1) {
                                env.NEXT_BUILD_NUMBER = 1
                            } else {
                                env.NEXT_BUILD_NUMBER = result[1]
                            }
                        }
                        if (env.VERSION_CORE != env.PRODUCT_VERSION_CORE) error "release hotfix version core(${env.VERSION_CORE}) should the same as prouction version(${env.PRODUCT_VERSION_CORE})"
                        currentBuild.displayName = "[Qat3] $env.VERSION_CORE-$env.PRE_RELEASE+$env.NEXT_BUILD_NUMBER"
                        //iosutils.buildProject(env.VERSION_CORE, env.PRE_RELEASE,  env.NEXT_BUILD_NUMBER , 'buildQat3')
                    }
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
                            ansible.publishIosVersionToQat( env.VERSION_CORE, env.PRE_RELEASE, env.NEXT_BUILD_NUMBER, PROP_DOWNLOAD_LINK, size, 'qat3')
                            version.setIosTag(env.VERSION_CORE, env.PRE_RELEASE, env.NEXT_BUILD_NUMBER, 'qat3')
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
                        jira.transferIssues(issueList, 'SEEKING APPROVAL', "ios-$env.VERSION_CORE-qat3", "ios-$env.VERSION_CORE-$env.PRE_RELEASE")
                }
            }
        }

        stage('QAT3 Notification') {
            steps {
                script {
                    teams.notifyQat3(PROP_TEAMS_NOTIFICATION, env.VERSION_CORE, env.PRE_RELEASE, env.NEXT_BUILD_NUMBER, env.PRODUCTION_ONLINE_BUILDNUMBER)
                }
            }
        }
    }
}
