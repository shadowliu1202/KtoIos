library 'utils'
def notifyQat3(def teamsTokenId, def versionCore, def preRelease, def newBuildNumber, def oldBuildNumber) {
    def tag = "$versionCore-$preRelease+$newBuildNumber"
    def updateIssues = "https://jira.higgstar.com/issues/?jql=project = APP AND fixVersion = ios-$versionCore-$preRelease"
    def releasePath = "$versionCore-$preRelease"
    wrap([$class: 'BuildUser']) {
        def definitions = [[name: 'hotfix issues', template: "[$versionCore] update from $oldBuildNumber to $newBuildNumber (<a href=\"$updateIssues\">issues</a>)"],
                                        [name: 'release by', template: "${env.BUIlD_USER}"],
                                        [name: 'download page', template: '<a href=\"https://qat3-mobile.affclub.xyz/\">link</a>']]

        def message = ">**[IOS][Hotfix][KTO Asia]** has been deployed to QAT3</br>version : **[$tag]($JENKINS_PROGET_HOME/feeds/app/ios/kto-asia/$releasePath/files)**"
        notify(teamsTokenId, message, definitions)
    }
}

def notifyQat1(def teamsTokenId, def versionCore, def preRelease, def nextBuildNumber, def onlineTag) {
    wrap([$class: 'BuildUser']) {
        def updateIssues = "https://jira.higgstar.com/issues/?jql=project = APP AND labels = ios-$versionCore-qat"
        def releasePath = "$versionCore-$preRelease"
        def tag = version.getReleaseTag(versionCore, preRelease, nextBuildNumber)
        def definitions = [[name: 'update issues', template: "update from $tag to $onlineTag (<a href=\"$updateIssues\">issues</a>)"],
                                    [name: 'release by', template: "$env.BUIlD_USER"],
                                    [name: 'download page', template: '<a href=\"https://qat1-mobile.affclub.xyz/\">link</a>']]
        def message = ">**[IOS][Qat][KTO Asia]** has been deployed to QAT1</br>version : **[$tag]($JENKINS_PROGET_HOME/feeds/app/ios/kto-asia/$releasePath/files)**"
        notify(teamsTokenId, message, definitions)
    }
}

def notify(def teamsTokenId, def message, def definitions) {
    withCredentials([string(credentialsId: "$teamsTokenId", variable: 'token')]) {
                office365ConnectorSend webhookUrl: token, message: message, factDefinitions: definitions
    }
}
