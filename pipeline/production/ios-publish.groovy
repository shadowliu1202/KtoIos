pipeline {
    agent {
        label 'master'
    }
    options {
        ansiColor('gnome-terminal')
    }
    environment {
        PROP_ROOT_RSA = '2cb1ac3a-2e81-474e-9846-25fad87697ef'
        PROP_GIT_CREDENTIALS_ID = '28ef89bf-70a2-475d-b5e0-a1ea12a8fcdb'
        PROP_GIT_REPO_URL = 'git@gitlab.higgstar.com:mobile/ktobet-asia-ios.git'        
        PROP_APPLE_STORE_API_KEY = '8110d047-b477-4759-a390-f858c2908a24'
        PROP_BUILD_ENVIRONMENT = "${env.ENV_BUILD_ENVIRONMENT}"
        PROP_DOWNSTREAM_JIRA_JOB = "${env.ENV_JIRA_JOB}"
        PROP_PRE_REALEASE = "${env.ENV_PRE_RELEASE}"
        PROP_STAGING_JOB = "${env.ENV_STAGING_JOB}"
        PROP_AGENT_KEYCHAIN_PASSWORD = 'ios_agent_keychain_password'
        PROP_BUILD_BRANCH = "${env.ENV_BUILD_BRANCH}"
        PROP_DOWNLOAD_LINK = "${params.ENV_IOS_DOWNLOAD_URL}"
        PROP_TEAMS_NOTIFICATION = "${env.ENV_TEAMS_NOTIFICATION_TOKEN}"
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
                                git ls-remote --tags --sort="v:refname" $PROP_GIT_REPO_URL | tail -n1 | sed 's/.*\\///; s/\\^{}//'
                            """,
                            returnStdout: true
                    ).trim()
                    echo "Compare latest version: $PROP_CURRENT_TAG"
                    echo sh(script: 'env|sort', returnStdout: true)
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
                         "BuildEnviroment=$PROP_BUILD_ENVIRONMENT"
                    ]) {
                    withCredentials([sshUserPrivateKey(credentialsId: "$RootCredentialsId", keyFileVariable: 'keyFile', passphraseVariable: '', usernameVariable: 'username')]) {
                        script {
                            def remote = [:]
                            remote.name = 'mis ansible'
                            remote.host = 'mis-ansible-app-01p'
                            remote.user = 'root'
                            remote.identityFile = keyFile
                            remote.allowAnyHosts = true
                            sshCommand remote: remote, command: """
                                ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_TIMEOUT=30; ansible-playbook -v /data-disk/brand-team/deploy-kto-ios-ipa.yml -u root --extra-vars "apkFeed=kto-asia tag=$ReleaseTag ipa_size=$IpaSize download_url=$PROP_DOWNLOAD_LINK" -i /data-disk/brand-team/qat1.ini
                            """
                        }
                    }
                    wrap([$class: 'BuildUser']) {
                        sshagent(["$JenkinsCredentialsId"]) {
                            sh """
                            git config user.name "devops"
                            git tag -f -a -m "release $BuildEnviroment version from ${env.BUIlD_USER}" $ReleaseTag
                            git push $PROP_GIT_REPO_URL $ReleaseTag
                        """
                        }
                    }
                }
            }

        }

        stage('Publish APK to Ansible') {
            steps {
                withEnv(["ReleaseTag=${env.PROP_RELEASE_TAG}",
                         "RootCredentialsId=$SYSADMIN_RSA",
                         "IpaSize=${env.IPA_SIZE}",
                         "BuildUser=${env.BUIlD_USER}",
                         "JenkinsCredentialsId=$PROP_GIT_CREDENTIALS_ID",
                         "BuildEnviroment=$PROP_BUILD_ENVIRONMENT"
                    ]) {

                withCredentials([sshUserPrivateKey(credentialsId: "$SYSADMIN_RSA", keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'user')]) {
                        script {
                            def remote = [:]
                            remote.name = "$AnsName"
                            remote.host = "$AnsHost"
                            remote.identityFile = identity
                            remote.user = user
                            remote.allowAnyHosts = true
                            sshCommand remote: remote, command: """
                                ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_TIMEOUT=30; ansible-playbook -v /data-disk/brand-deployment-document/playbooks/deploy-kto-ios-ipa.yml --extra-vars "apkFeed=kto-asia tag=$ReleaseTag ipa_size=$IpaSize download_url=$PROP_DOWNLOAD_LINK"
                            """
                        }
                    }
                    wrap([$class: 'BuildUser']) {
                        sshagent(["$JenkinsCredentialsId"]) {
                            sh """
                            git config user.name "devops"
                            git tag -f -a -m "release $BuildEnviroment version from ${env.BUIlD_USER}" $ReleaseTag
                            git push $PROP_GIT_REPO_URL $ReleaseTag
                        """
                        }
                    }
                }
            }

        }

        stage('Update jira issues') {
            steps {
                script {
                    build job: "$PROP_DOWNSTREAM_JIRA_JOB",
                            parameters: [text(name: 'CURRENT_TAG', value: "${env.PROP_CURRENT_TAG}"),
                                         text(name: 'RELEASE_TAG', value: "${env.PROP_RELEASE_TAG}")]
                }
            }
        }

        stage('Notification') {
            steps {
                script {
                    withEnv(["ReleaseTag=${env.PROP_RELEASE_TAG}",
                             "BuildEnvrioment=${PROP_BUILD_ENVIRONMENT.toLowerCase()}",
                             "ReleaseVersion=$PROP_RELEASE_VERSION",
                             "ReleaseVersionCore=$PROP_RELEASE_VERSIONCORE",
                             "TeamsToken=$PROP_TEAMS_NOTIFICATION"
                    ]) {
                        office365ConnectorSend webhookUrl: "$TeamsToken",
                                message: ">**[Android] [KTO Asia]** has been deployed to $BuildEnvrioment</br>version : **[$ReleaseTag]($JENKINS_PROGET_HOME/feeds/app/android/kto-asia/$ReleaseVersion/files)**",
                                factDefinitions: [[name: 'Download Page', template: '<a href="https://qat1-mobile.affclub.xyz/">Download Page</a>'],
                                                  [name: 'Related Issues', template: "<a href=\"https://jira.higgstar.com/issues/?jql=project = APP AND labels = android-$ReleaseVersionCore-$BuildEnvrioment\">Jira Issues</a>"]]
                    }
                }
            }
        }
    }
}
