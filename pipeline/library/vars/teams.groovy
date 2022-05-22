def notifyQat3(def teamsToken, def versionCore, def preRelease, def newBuildNumber,def oldBuildNumber, def testFlightLink) {
    def tag = "$versionCore-$preRelease+$newBuildNumber"
    def updateIssues = "https://jira.higgstar.com/issues/?jql=project = APP AND labels = ios-$versionCore-$preRelease"
    def releasePath = "$versionCore-$preRelease"
    wrap([$class: 'BuildUser']) {
        office365ConnectorSend webhookUrl: "$TeamsToken",
                                message: ">**[IOS][Hotfix][KTO Asia]** has been deployed to QAT3</br>version : **[$tag]($JENKINS_PROGET_HOME/feeds/app/ios/kto-asia/$releasePath/files)**",
                                factDefinitions: [[name: 'testflight', template: "<a href=\"$testFlightLink\">Download Page</a>"],
                                                  [name: 'hotfix issues', template: "[$versionCore] $oldBuildNumber to $newBuildNumber (<a href=\"$updateIssues\">issues</a>)"],
                                                  [name: 'release by', template: "${env.BUIlD_USER}"]]
    }
}
