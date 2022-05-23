def publishIosVersionToQat(def preRelease, def versionCore, def buildNumber, def download_url, def size, def buildEnviroment) {
    string publishVersion = "$versionCore+$buildNumber"
    if (buildNumber == 1) {
        publishVersion = "$versionCore"
    }
    string rootCredentialsId = '2cb1ac3a-2e81-474e-9846-25fad87697ef'
    string gitRepo = 'git@gitlab.higgstar.com:mobile/ktobet-asia-ios.git'
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
    def gitCredentialsId = '28ef89bf-70a2-475d-b5e0-a1ea12a8fcdb'
    wrap([$class: 'BuildUser']) {
        sshagent(["$gitCredentialsId"]) {
            sh script:"""
                git config user.name "devops"
                git tag -f -a -m "release $buildEnviroment version from ${env.BUIlD_USER}" $releaseTag
                git push $gitRepo $releaseTag
            """ , returnStatus:true
        }
    }
}

def getProductionTag() {
    // Get Production version
    def sysadmin_rsa = '0dd067b6-8bd0-4c0a-9cb7-fb374ed7084e'
    withCredentials([sshUserPrivateKey(credentialsId: "$sysadmin_rsa", keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'user')]) {
        def remote = [:]
        remote.name = 'mis ansible'
        remote.host = '10.10.16.16'
        remote.user = user
        remote.identityFile = identity
        remote.allowAnyHosts = true
        def commandResult = sshCommand remote: remote, command: "curl -s https://appkto.com/ios/api/get-ios-ipa-version | jq -r '.data.ipaVersion'", failOnError : false
        echo "$commandResult"
        String[] result = commandResult.trim().split('\\+')
        def productionTag = ''
        if (result.length == 1) {
            productionTag = "${result[0]}-release"
        } else {
            productionTag = "${result[0]}-release+${result[1]}"
        }
        echo "production tag = $productionTag"
        return productionTag
    }
}

def getQatTag() {
     // Get Production version
     def rootRsa = '2cb1ac3a-2e81-474e-9846-25fad87697ef'
     withCredentials([sshUserPrivateKey(credentialsId: "$rootRsa", keyFileVariable: 'keyFile', passphraseVariable: '', usernameVariable: 'username')]) {
        def remote = [:]
            remote.name = 'mis ansible'
            remote.host = 'mis-ansible-app-01p'
            remote.user = username
            remote.identityFile = keyFile
            remote.allowAnyHosts = true
        def commandResult = sshCommand remote: remote, command: """
            ssh root@172.16.100.122 'curl -s https://qat1-mobile.affclub.xyz/ios/api/get-ios-ipa-version | jq -r '.data.ipaVersion'
        """
        echo "Get QAT version ${commandResult.trim()}"
        return commandResult
     }
}
