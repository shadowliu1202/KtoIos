def getChangeLogIssues() {
    def issueList = []
    def issueKeys = jiraIssueSelector(issueSelector: [$class: 'DefaultIssueSelector'])
    for (issue in issueKeys) {
        issueList.add(issue)
    }
    return issueList.toSorted()
}

@NonCPS
def getChangeIssues() {
    def issueList = []
    def changeLogSets = currentBuild.changeSets
    for (int i = 0; i < changeLogSets.size(); i++) {
        def entries = changeLogSets[i].items
        for (int j = 0; j < entries.length; j++) {
            issueList.addAll(entries[j].comment.findAll('APP-\\d+'))
        }
    }
    return issueList.toSorted()
}

def transferIssues(jiraIssues = [], transferAction = null , envLabel = null , newVersion = null) {
    if (newVersion != null) {
        jiraNewVersion site: 'Higgs-Jira', failOnError: false, version: [name: "$newVersion", project: 'APP']
    }
    for (issue in jiraIssues) {
        def result = jiraGetIssue idOrKey:issue, site: 'Higgs-Jira', failOnError: false
        def updateFields = [:]
        if (result != null && result.data != null ) {
            if (newVersion != null) {
                def versions = result.data.fields.fixVersions << [ name:"$newVersion" ]
                updateFields['fixVersions'] = versions
            }
            if (envLabel != null) {
                def labels = result.data.fields.labels << "$envLabel"
                updateFields['labels'] = labels
            }
        }
        //updateIssue = [fields: [labels: ["$envLabel"], fixVersions:fixVersions]]
        def updateIssue = [fields:updateFields]
        echo "updateIssue $updateIssue"
        jiraEditIssue failOnError: false, site: 'Higgs-Jira', idOrKey: "$issue", issue: updateIssue
        def jiraTransitions = jiraGetIssueTransitions failOnError: false, idOrKey: "$issue", site: 'Higgs-Jira'
        def data = jiraTransitions.data
        if (data != null && data.transitions != null) {
            for (transition in data.transitions) {
                if (transition.name == "$transferAction") {
                    echo "transfer $issue with $transition"
                    def transitionInput = [transition: [id: "$transition.id"]]
                    jiraTransitionIssue failOnError: false, site: 'Higgs-Jira', input:transitionInput, idOrKey: "$issue"
                    break
                }
            }
        }
    }
}
