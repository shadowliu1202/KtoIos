def checkoutIosKtoAsia(branch, compareTag) {
    def gitCredential = '28ef89bf-70a2-475d-b5e0-a1ea12a8fcdb'
    def gitRepo = 'git@gitlab.higgstar.com:mobile/ktobet-asia-ios.git'

    checkout([$class: 'GitSCM',
            branches         : [[name: "refs/heads/$branch"]],
            browser          : [$class: 'GitLab', repoUrl: "$gitRepo", version: '14.4'],
            extensions       : [[$class: 'ChangelogToBranch', options: [compareRemote: 'refs', compareTarget: "tags/$compareTag"]],
                                [$class: 'AuthorInChangelog'],
                                [$class: 'BuildSingleRevisionOnly']],
            userRemoteConfigs: [[credentialsId: "$gitCredential",
                                refspec      : "+refs/heads/$branch:refs/remotes/origin/$branch +refs/heads/tags/*:refs/remotes/origin/tags/*",
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
    int testFlightBuildNumber = 0
    def appleStoreKeyId = '2XHCS3W99M'
    withEnv(["KEY_ID=$appleStoreKeyId"]) {
        def statusCode  = sh script:"fastlane getNextTestflightBuildNumber releaseTarget:$enviroment targetVersion:$versionCore", returnStatus:true
        if (statusCode == 0) {
            testFlightBuildNumber = readFile('fastlane/buildNumber').trim() as int
        }
    }
    return  testFlightBuildNumber
}

def getNextBuildNumber(productionTag, versionCore, enviroment) {
     withEnv(['MATCH_PASSWORD=password']) {
        withCredentials([file(credentialsId: '63f71ab5-5473-43ca-9191-b34cd19f1fa1', variable: 'API_KEY'),
                    string(credentialsId: 'ios_agent_keychain_password', variable: 'KEYCHAIN_PASSWORD')
        ]) {
                def productBuildNumber = getProductBuildNumber(productionTag)
                def testFlightBuildNumber = getTestFlightBuildNumber(versionCore, enviroment)
                return Math.max(productBuildNumber, testFlightBuildNumber) + 1
        }
     }
}

def buildQat3Project(branch, compareTag, versionCore, preRelease,nextBuildNumber) {
    withEnv(['MATCH_PASSWORD=password']) {
        withCredentials([file(credentialsId: '63f71ab5-5473-43ca-9191-b34cd19f1fa1', variable: 'API_KEY'),
                    string(credentialsId: 'ios_agent_keychain_password', variable: 'KEYCHAIN_PASSWORD')
        ]) {
            buildProject(versionCore, preRelease, nextBuildNumber, 'buildQat3')
        }
    }
}

def buildProject(versionCore, preRelease, nextBuildNumber, targetLane) {
    sh """
        pod install --repo-update
        fastlane $targetLane buildVersion:$nextBuildNumber appVersion:$versionCore
    """
    uploadProgetPackage artifacts: 'output/*.ipa', feedName: 'app', groupName: 'ios', packageName: 'kto-asia', version: "$versionCore-$preRelease", description: "compile version:$nextBuildNumber"
}
