
def getReleaseTag(core, preRelease, buildNumber) {
    ehco "release : $core $preRelease $buildNumber"
    if (buildNumber == '1') {
        return "$core-$preRelease"
    } else {
        return "$core-$preRelease+$buildNumber"
    }
}
