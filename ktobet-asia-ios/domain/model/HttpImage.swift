import SharedBu

extension HttpImage {
    var fullpath: String {
        Configuration.host[DI.resolve(LocalStorageRepositoryImpl.self)!.getCultureCode()]! + self.path()
    }
    var thumbnailFullPath: String {
        Configuration.host[DI.resolve(LocalStorageRepositoryImpl.self)!.getCultureCode()]! + self.thumbnailPath()
    }
}
