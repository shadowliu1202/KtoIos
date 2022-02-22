import SharedBu

extension HttpImage {
    var fullpath: String {
        Configuration.host + self.path()
    }
    var thumbnailFullPath: String {
        Configuration.host + self.thumbnailPath()
    }
}
