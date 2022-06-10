
def getReleaseTag(core, preRelease, buildNumber) {
    echo "release tag: $core $preRelease $buildNumber"
    if (buildNumber.toString() == '1') {
        return "$core-$preRelease"
    } else {
        return "$core-$preRelease+$buildNumber"
    }
}

def getReleaseVersion(core, buildNumber) {
    echo "release version: $core $buildNumber"
    if (buildNumber.toString() == '1') {
        return "$core"
    } else {
        return "$core+$buildNumber"
    }
}

def setIosTag(core, preRelease, buildNumber, buildEnviroment) {
    def releaseTag = getReleaseTag(core, preRelease, buildNumber)
    string gitRepo = 'git@gitlab.higgstar.com:mobile/ktobet-asia-ios.git'
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
