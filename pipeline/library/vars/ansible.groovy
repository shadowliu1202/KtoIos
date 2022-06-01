def publishIosOnlineVersion( def versionCore, def preRelease, def buildNumber, def download_url, def size) {
    if (preRelease.toString() == 'rc') {
        publishToIDC('10.10.16.15', versionCore, buildNumber, download_url, size)
        setOnlineVersion('ios', '10.10.16.15', versionCore, buildNumber)
    }else if (preRelease.toString() == 'release') {
        publishToIDC('10.10.16.16', versionCore, buildNumber, download_url, size)
        setOnlineVersion('ios', '10.10.16.16', versionCore, buildNumber)
    }
}

def publishToIDC(def server, def versionCore, def buildNumber, def download_url, def size) {
    def sysAdmin = '0dd067b6-8bd0-4c0a-9cb7-fb374ed7084e'
    string publishVersion = "$versionCore+$buildNumber"
    if (buildNumber == 1) {
        publishVersion = "$versionCore"
    }
    withCredentials([sshUserPrivateKey(credentialsId: "$sysAdmin", keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'user')]) {
        script {
            def remote = [:]
            remote.name = 'mis ansible'
            remote.host = "$server"
            remote.user = user
            remote.identityFile = identity
            remote.allowAnyHosts = true
        sshCommand remote: remote, command: """
            ansible-playbook -v /data-disk/brand-deployment-document/playbooks/deploy-kto-ios-ipa.yml --extra-vars "apkFeed=kto-asia tag=$publishVersion ipa_size=$size download_url=$download_url"
        """
        }
    }
}

def publishIosVersionToQat(def versionCore, def preRelease, def buildNumber, def download_url, def size, def buildEnviroment) {
    string publishVersion = "$versionCore+$buildNumber"
    echo "publishIosVersionToQat $versionCore $preRelease $buildNumber"
    if (buildNumber.toString() == '1') {
         echo 'buildNumber is 1'
        publishVersion = "$versionCore"
    }
    echo "publishIosVersionToQat $publishVersion"
    string rootCredentialsId = '2cb1ac3a-2e81-474e-9846-25fad87697ef'
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
}

def getIosOnlineVersion(enviroment) {
    if (enviroment.toString() == 'stg') {
        return getOnlineVersion('ios', '10.10.16.15', 'rc')
    }else if (enviroment.toString() == 'pro') {
        return getOnlineVersion('ios', '10.10.16.16', 'release')
    }
}

def getAndroidOnlineVersion(enviroment) {
    if (enviroment.toString() == 'stg') {
        return getOnlineVersion('android', '10.10.16.15', 'rc')
    }else if (enviroment.toString() == 'pro') {
        return getOnlineVersion('android', '10.10.16.16', 'release')
    }
}

def getOnlineVersion(platform, server, preRelease) {
    def sysadmin_rsa = '0dd067b6-8bd0-4c0a-9cb7-fb374ed7084e'
    withCredentials([sshUserPrivateKey(credentialsId: "$sysadmin_rsa", keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'user')]) {
        def remote = [:]
        remote.name = 'mis ansible'
        remote.host = server
        remote.identityFile = identity
        remote.user = user
        remote.allowAnyHosts = true
        def commandResult = sshCommand remote: remote, command:"cat /data-disk/mobile-deployment-document/${platform}.version"
        String[] result = commandResult.trim().split('\\+')
        def tag = ''
        if (result.length == 1) {
            tag = "${result[0]}-$preRelease"
        } else {
            tag = "${result[0]}-$preRelease+${result[1]}"
        }
        echo "$preRelease online tag = $tag"
        return tag
    }
}

def setOnlineVersion(platform, server, versionCore, buildNumber) {
    def sysadmin_rsa = '0dd067b6-8bd0-4c0a-9cb7-fb374ed7084e'
    withCredentials([sshUserPrivateKey(credentialsId: "$sysadmin_rsa", keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'user')]) {
        def tag = "$versionCore+$buildNumber"
        echo "set online tag = $tag"
        def remote = [:]
        remote.name = 'mis ansible'
        remote.host = server
        remote.identityFile = identity
        remote.user = user
        remote.allowAnyHosts = true
        sshCommand remote: remote, command:"echo $tag > /data-disk/mobile-deployment-document/${platform}.version"
    }
}

def getStagingTag() {
    return getOnlineTag('https://mobile.staging.support', '10.10.16.15', 'rc')
}

def getProductionTag() {
    return getOnlineTag('https://appkto.com', '10.10.16.16', 'release')
}

def getOnlineTag(host, server, preRelease) {
    // Get Production version
    def sysadmin_rsa = '0dd067b6-8bd0-4c0a-9cb7-fb374ed7084e'
    withCredentials([sshUserPrivateKey(credentialsId: "$sysadmin_rsa", keyFileVariable: 'identity', passphraseVariable: '', usernameVariable: 'user')]) {
        def remote = [:]
        remote.name = 'mis ansible'
        remote.host = server
        remote.user = user
        remote.identityFile = identity
        remote.allowAnyHosts = true
        def commandResult = sshCommand remote: remote, command: "curl -s ${host}/ios/api/get-ios-ipa-version | jq -r '.data.ipaVersion'", failOnError : false
        echo "$commandResult"
        String[] result = commandResult.trim().split('\\+')
        def tag = ''
        if (result.length == 1) {
            tag = "${result[0]}-$preRelease"
        } else {
            tag = "${result[0]}-$preRelease+${result[1]}"
        }
        echo "$preRelease online tag = $tag"
        return tag
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
            ssh root@172.16.100.122 'curl -s https://qat1-mobile.affclub.xyz/ios/api/get-ios-ipa-version'
        """
        def tag = sh(script: "echo '${commandResult.trim()}' | jq -r '.data.ipaVersion'", returnStdout: true).trim()
        echo "Get QAT version ${tag.trim()}"
        String[] buildNumber = tag.trim().split('\\+')
        String[] version = tag.trim().split('-')

        def qatTag = ''
        if (buildNumber.length == 1) {
            qatTag = "${version[0]}-dev"
        } else {
            qatTag = "${version[0]}-dev+${buildNumber[1]}"
        }
        return qatTag
     }
}
