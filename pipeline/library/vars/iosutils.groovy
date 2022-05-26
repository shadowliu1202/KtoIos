def checkoutTagOnIosKtoAsia(tag, compareTag) {
    echo "checkoutTagOnIosKtoAsia $tag , $compareTag"
    checkoutIos("refs/tags/$tag", "+refs/heads/master:refs/remotes/origin/master", compareTag)
}

def checkoutIosKtoAsia(branch, compareTag = null) {
    checkoutIos("refs/heads/$branch", "+refs/heads/$branch:refs/remotes/origin/$branch", compareTag)
}

def checkoutIos(branchName, branchRefspec, compareTag = null) {
    def gitCredential = '28ef89bf-70a2-475d-b5e0-a1ea12a8fcdb'
    def gitRepo = 'git@gitlab.higgstar.com:mobile/ktobet-asia-ios.git'
    def gitExtensions = [[$class: 'AuthorInChangelog'], [$class: 'BuildSingleRevisionOnly']]
    if (compareTag != null) {
        gitExtensions = [[$class: 'ChangelogToBranch', options:  [compareRemote: 'refs', compareTarget: "tags/$compareTag"]],
                                [$class: 'AuthorInChangelog'],
                                [$class: 'BuildSingleRevisionOnly']]
    }
    checkout([$class: 'GitSCM',
            branches         : [[name: "$branchName"]],
            browser          : [$class: 'GitLab', repoUrl: "$gitRepo", version: '14.4'],
            extensions       : gitExtensions,
            userRemoteConfigs: [[credentialsId: "$gitCredential",
                                refspec      : "$branchRefspec +refs/heads/tags/*:refs/remotes/origin/tags/*",
                                url          : "$gitRepo"]]
    ])
}

def getProductBuildNumber(productionTag) {
    string onlineBuildVersion = productionTag.trim().split('\\+')
    int lastBuildNumber = 1
    if (onlineBuildVersion.length == 1) {
        echo "$productionTag has no build number"
    } else {
        lastBuildNumber = (onlineBuildVersion[1] as int)
    }
    return lastBuildNumber
}

def getTestFlightBuildNumber(versionCore, enviroment) {
    withEnv(['MATCH_PASSWORD=password', 'KEY_ID=2XHCS3W99M']) {
        withCredentials([file(credentialsId: '63f71ab5-5473-43ca-9191-b34cd19f1fa1', variable: 'API_KEY'),
                    string(credentialsId: 'ios_agent_keychain_password', variable: 'KEYCHAIN_PASSWORD')
        ]) {
            int testFlightBuildNumber = 0
            def statusCode  = sh script:"fastlane getNextTestflightBuildNumber releaseTarget:$enviroment targetVersion:$versionCore", returnStatus:true
            if (statusCode == 0) {
                testFlightBuildNumber = readFile('fastlane/buildNumber').trim() as int
            }
            return  testFlightBuildNumber
        }
    }
}

def getNextBuildNumber(productionTag, versionCore, enviroment) {
     withEnv(['MATCH_PASSWORD=password', 'KEY_ID=2XHCS3W99M']) {
        withCredentials([file(credentialsId: '63f71ab5-5473-43ca-9191-b34cd19f1fa1', variable: 'API_KEY'),
                    string(credentialsId: 'ios_agent_keychain_password', variable: 'KEYCHAIN_PASSWORD')
        ]) {
                def productBuildNumber = getProductBuildNumber(productionTag)
                def testFlightBuildNumber = getTestFlightBuildNumber(versionCore, enviroment)
                return Math.max(productBuildNumber, testFlightBuildNumber) + 1
        }
     }
}

def buildProject(versionCore, preRelease, nextBuildNumber, targetLane) {
    withEnv(['MATCH_PASSWORD=password', 'KEY_ID=2XHCS3W99M']) {
        withCredentials([file(credentialsId: '63f71ab5-5473-43ca-9191-b34cd19f1fa1', variable: 'API_KEY'),
                    string(credentialsId: 'ios_agent_keychain_password', variable: 'KEYCHAIN_PASSWORD')
        ]) {
            sh """
                pod install --repo-update
                fastlane $targetLane buildVersion:$nextBuildNumber appVersion:$versionCore
            """
        }
    }
    uploadProgetPackage artifacts: 'output/*.ipa', feedName: 'app', groupName: 'ios', packageName: 'kto-asia', version: "$versionCore-$preRelease", description: "compile version:$nextBuildNumber"
}

def updateTestFlight(versionCore, nextBuildNumber,enviroment){
    withEnv(['MATCH_PASSWORD=password', 'KEY_ID=2XHCS3W99M']) {
        withCredentials([file(credentialsId: '63f71ab5-5473-43ca-9191-b34cd19f1fa1', variable: 'API_KEY'),
                    string(credentialsId: 'ios_agent_keychain_password', variable: 'KEYCHAIN_PASSWORD')
        ]) {
            sh """
                pod install --repo-update
                fastlane uploadTestflight buildVersion:$nextBuildNumber appVersion:$versionCore releaseTarget:$enviroment
            """
        }
    }
}
