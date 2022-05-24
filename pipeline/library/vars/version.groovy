
def getReleaseTag(core, preRelease, buildNumber) {
    echo "release : $core $preRelease $buildNumber"
    if (buildNumber.toString() == '1') {
        return "$core-$preRelease"
    } else {
        return "$core-$preRelease+$buildNumber"
    }
}
