def notifyQat3(def teamsTokenId, def versionCore, def preRelease, def newBuildNumber, def oldBuildNumber) {
    def tag = "$versionCore-$preRelease+$newBuildNumber"
    def updateIssues = "https://jira.higgstar.com/issues/?jql=project = APP AND labels = ios-$versionCore-$preRelease"
    def releasePath = "$versionCore-$preRelease"
    wrap([$class: 'BuildUser']) {
        withCredentials([string(credentialsId: "$teamsTokenId", variable: 'token')]) {
           office365ConnectorSend webhookUrl: "$token",
                                message: ">**[IOS][Hotfix][KTO Asia]** has been deployed to QAT3</br>version : **[$tag]($JENKINS_PROGET_HOME/feeds/app/ios/kto-asia/$releasePath/files)**",
                                factDefinitions: [[name: 'hotfix issues', template: "[$versionCore] update from $oldBuildNumber to $newBuildNumber (<a href=\"$updateIssues\">issues</a>)"],
                                                  [name: 'download page', template: "<a href=\"https://qat3-mobile.affclub.xyz/\">link</a>"],
                                                  [name: 'release by', template: "${env.BUIlD_USER}"]]
        }
    }
}
