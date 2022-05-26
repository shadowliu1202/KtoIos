library 'utils'
def notifyPublish(def teamsTokenId, def versionCore, def preRelease, def nextBuildNumber, def buildEnviroment, def downloadPage) {
    wrap([$class: 'BuildUser']) {
        def totalIssues = "https://jira.higgstar.com/issues/?jql=project = APP AND fixVersion = ios-$versionCore"
        def releasePath = "$versionCore-$preRelease"
        def tag = version.getReleaseTag(versionCore, preRelease, nextBuildNumber)
        def definitions = [[name: 'release by', template: "$env.BUIlD_USER"],
                                    [name: 'download page', template: "<a href=\"$downloadPage\">link</a>"],
                                    [name: 'total issues', templates: "<a href=\"$totalIssues\">issues ready for production</a>"]]
        def message = ">**[IOS][KTO Asia]** has been published to ${buildEnviroment.toUpperCase()} </br>version : **[$tag]($JENKINS_PROGET_HOME/feeds/app/ios/kto-asia/$releasePath/files)**"
        notify(teamsTokenId, message, definitions)
    }
}

def notifyProductionRelease(def teamsTokenId, def versionCore, def preRelease, def nextBuildNumber, def onlineTag, def buildEnviroment, def selftestLink,def backupLink) {
    wrap([$class: 'BuildUser']) {
        def totalIssues = "https://jira.higgstar.com/issues/?jql=project = APP AND fixVersion = ios-$versionCore"
        def releasePath = "$versionCore-$preRelease"
        String[] result =  onlineTag.split('\\+')
        String[] core =  eonlineTag.split('-')
        def onlineVersion = core[0]
        if (result.length > 1) {
            onlineVersion += "+$result[1]"
        }        
        def tag = version.getReleaseTag(versionCore, preRelease, nextBuildNumber)
        def definitions = [[name: 'release issues', template: "from $onlineVersion to $versionCore+$nextBuildNumber (<a href=\"$totalIssues\">issues</a>)"],
                                    [name: 'release by', template: "$env.BUIlD_USER"],
                                    [name: 'testflight', template: "<a href=\"$testFlightPage\">selftest</a>, <a href=\"$testFlightPage\">backup</a>"]]
        def message = ">**[IOS][KTO Asia]** production has been released</br>version : **[$tag]($JENKINS_PROGET_HOME/feeds/app/ios/kto-asia/$releasePath/files)**"
        notify(teamsTokenId, message, definitions)
    }
}

def notifyRelease(def teamsTokenId, def versionCore, def preRelease, def nextBuildNumber, def onlineTag, def buildEnviroment, def downloadPage, def testFlightPage) {
    wrap([$class: 'BuildUser']) {
        def updateIssues = "https://jira.higgstar.com/issues/?jql=project = APP AND labels = ios-$versionCore-$buildEnviroment"
        def releasePath = "$versionCore-$preRelease"
        def tag = version.getReleaseTag(versionCore, preRelease, nextBuildNumber)
        def definitions = [[name: 'update issues', template: "update from $onlineTag to $tag (<a href=\"$updateIssues\">issues</a>)"],
                                    [name: 'release by', template: "$env.BUIlD_USER"],
                                    [name: 'download page', template: "<a href=\"$downloadPage\">link</a>"],
                                    [name: 'testflight page', template: "<a href=\"$testFlightPage\">link</a>"]]
        def message = ">**[IOS][KTO Asia]** has been released to ${buildEnviroment.toUpperCase()} </br>version : **[$tag]($JENKINS_PROGET_HOME/feeds/app/ios/kto-asia/$releasePath/files)**"
        notify(teamsTokenId, message, definitions)
    }
}

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
        def definitions = [[name: 'update issues', template: "update from $onlineTag to $tag (<a href=\"$updateIssues\">issues</a>)"],
                                    [name: 'release by', template: "$env.BUIlD_USER"],
                                    [name: 'download page', template: '<a href=\"https://qat1-mobile.affclub.xyz/\">link</a>']]
        def message = ">**[IOS][Dev][KTO Asia]** has been deployed to QAT1</br>version : **[$tag]($JENKINS_PROGET_HOME/feeds/app/ios/kto-asia/$releasePath/files)**"
        notify(teamsTokenId, message, definitions)
    }
}

def notify(def teamsTokenId, def message, def definitions) {
    withCredentials([string(credentialsId: "$teamsTokenId", variable: 'token')]) {
                office365ConnectorSend webhookUrl: token, message: message, factDefinitions: definitions
    }
}
