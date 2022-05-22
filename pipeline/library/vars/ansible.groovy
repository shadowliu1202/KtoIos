def publishIosVersionToQat(def versionCore,def buildNumber,def download_url, def size) {
    if(){
        
    }
    string publishVersion = "$versionCore+$buildNumber"
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
                ANSIBLE_HOST_KEY_CHECKING=False ANSIBLE_TIMEOUT=30; ansible-playbook -v /data-disk/brand-team/deploy-kto-ios-ipa.yml -u root --extra-vars "apkFeed=kto-asia tag=$HotfixVersion ipa_size=$IpaSize download_url=$DownloadLink" -i /data-disk/brand-team/qat3.ini
            """
        }
    }
    sshagent(["$JenkinsCredentialsId"]) {
        sh script:"""
            git config user.name "devops"
            git tag -f -a -m "release $BuildEnviroment version from ${env.BUIlD_USER}" $ReleaseTag
            git push $PROP_GIT_REPO_URL $ReleaseTag
        """ , returnStatus:true
    }
}
