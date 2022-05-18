import SharedBu

extension HttpImage {
    var fullpath: String {
        Configuration.host[Localize.getSupportLocale().cultureCode()]! + self.path()
    }
    var thumbnailFullPath: String {
        Configuration.host[Localize.getSupportLocale().cultureCode()]! + self.thumbnailPath()
    }
}
