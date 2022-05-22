def publishIosVersionToQat(def preRelease, def versionCore, def buildNumber, def download_url, def size, def buildEnviroment) {
    string publishVersion = "$versionCore+$buildNumber"
    if (buildNumber == 1) {
        publishVersion = "$versionCore"
    }
    string rootCredentialsId = "$PROP_ROOT_RSA"
    string ktoAsiaGitRepo = "$PROP_GIT_REPO_URL"
    string releaseTag = "$versionCore-$preRelease+$buildNumber"
    withCredentials([sshUserPrivateKey(credentialsId: "$rootCredentialsId", keyFileVariable: 'keyFile', passphraseVariable: '', usernameVariable: 'username')]) {
        script {
            def remote = [:]
            remote.name = 'mis ansible'
            remote.host = 'mis-ansible-app-01p'
            remote.user = 'root'
            remote.identityFile = keyFile
            remote.allowAnyHosts = true

            sshCommand remote: remote, command: """
                ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_TIMEOUT=30; ansible-playbook -v /data-disk/brand-team/deploy-kto-ios-ipa.yml -u root --extra-vars "apkFeed=kto-asia tag=$publishVersion ipa_size=$size download_url=$download_url" -i /data-disk/brand-team/${buildEnviroment.toLowerCase()}.ini
            """
        }
    }
    wrap([$class: 'BuildUser']) {
        sshagent(["$JenkinsCredentialsId"]) {
            sh script:"""
                git config user.name "devops"
                git tag -f -a -m "release $buildEnviroment version from ${env.BUIlD_USER}" $releaseTag
                git push $ktoAsiaGitRepo $releaseTag
            """ , returnStatus:true
        }
    }
}

def getProductionTag(){
     // Get Production version
    withCredentials([sshUserPrivateKey(credentialsId: "$PROP_SYSADMIN_RSA", keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'user')]) {
        def remote = [:]
        remote.name = 'mis ansible'
        remote.host = "10.10.16.16"
        remote.user = user
        remote.identityFile = identity
        remote.allowAnyHosts = true
        def commandResult = sshCommand remote: remote, command: "curl -s https://appkto.com/ios/api/get-ios-ipa-version | jq -r '.data.ipaVersion'", failOnError : false
        echo "$commandResult"
        String[] result = commandResult.trim().split('\\+')
        def productionTag = ""
        if (result.length == 1) {
            productionTag = "${result[0]}-release"
        } else {
            productionTag = "${result[0]}-release+${result[1]}"
        }
        echo "production tag = $productionTag"
        return productionTag
    }
}