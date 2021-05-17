import UIKit
import Photos


class ImagePickerViewController: UIViewController {
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var countLabel: UILabel!
    @IBOutlet private weak var uploadButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private var tableHeight: NSLayoutConstraint!
    
    var delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate)?
    var selectedImageLimitCount = 3
    var imageLimitMBSize = 20
    var allowImageFormat = ["PNG", "JPG", "BMP", "JPEG"]
    var completion: ((_ assets: [UIImage]) -> Void)?
    var cancel: (() -> ())?
    var showImageCountLimitAlert: ((_ view: UIView) -> ())?
    var showImageFormatInvalidAlert: ((_ view: UIView) -> ())?
    var showImageSizeLimitAlert: ((_ view: UIView) -> ())?
    
    private var activityIndicator = UIActivityIndicatorView(style: .large)
    private var imageRequestID: PHImageRequestID?
    private let albumButton =  UIButton(type: .custom)
    private var albums: [AlbumModel] = []
    private var photoAssets: PHFetchResult<PHAsset> = PHFetchResult()
    private var selectedAlbum: AlbumModel?
    private var selectedImages: [UIImage] = []
    private var selectedPhotoAssets: [PHAsset] = [] {
        didSet {
            if selectedPhotoAssets.count != 0 {
                uploadButton.isValid = true
                uploadButton.alpha = 1
            } else {
                uploadButton.isValid = false
                uploadButton.alpha = 0.5
            }
        }
    }
    private lazy var fetchOptions: PHFetchOptions = {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return fetchOptions
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self)
        fetchAllPhotoAlbum()
        fetchAlbums()
        uploadButton.isValid = false
        uploadButton.alpha = 0.5
        albumButton.setTitle(Localize.string("common_all"), for: .normal)
        albumButton.setImage(UIImage(named: "iconChevronDown16"), for: .normal)
        albumButton.semanticContentAttribute = .forceRightToLeft
        albumButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        albumButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        albumButton.addTarget(self, action: #selector(showAlbum), for: .touchUpInside)
        self.navigationItem.titleView = albumButton
        if let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            let horizontalSpacing = flowLayout.scrollDirection == .vertical ? flowLayout.minimumInteritemSpacing : flowLayout.minimumLineSpacing
            let cellWidth = (view.frame.width - max(0, 3 - 1)*horizontalSpacing) / 3
            flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
        }
        
        activityIndicator.center = self.view.center
        self.view.addSubview(activityIndicator)
        countLabel.text = "\(selectedPhotoAssets.count)/\(selectedImageLimitCount)"
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if tableView.contentSize.height > view.frame.height * 0.6 {
            tableHeight.constant = view.frame.height * 0.6
        } else {
            tableHeight.constant = tableView.contentSize.height
        }
    }
    
    @objc private func showAlbum(_ sender: UIButton) {
        tableView.isHidden = !tableView.isHidden
    }
    
    @IBAction private func upload(_ sender: UIButton) {
        startActivityIndicator(activityIndicator: activityIndicator)
        selectedImages = []
        for asset in selectedPhotoAssets {            
            selectedImages.append(asset.convertAssetToImage())
        }
        
        stopActivityIndicator(activityIndicator: activityIndicator)
        completion?(selectedImages)
    }
    
    private func fetchAlbum(type: PHAssetCollectionType, subtype: PHAssetCollectionSubtype) {
        let options = PHFetchOptions()
        let name: String? = subtype == .smartAlbumUserLibrary ? "全部" : nil
        let allPhotoAlbum = PHAssetCollection.fetchAssetCollections(with: type, subtype: subtype, options: options)
        allPhotoAlbum.enumerateObjects{[weak self] (object: AnyObject!, count: Int, stop: UnsafeMutablePointer) in
            guard let self = self else { return }
            if object is PHAssetCollection {
                let obj: PHAssetCollection = object as! PHAssetCollection
                guard let asset = self.getAssets(fromCollection: obj).firstObject else { return }
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.resizeMode = .fast
                options.isSynchronous = false
                options.isNetworkAccessAllowed = true
                
                let manager = PHImageManager.default()
                let newSize = CGSize(width: 125, height: 125)
                _ = manager.requestImage(for: asset, targetSize: newSize, contentMode: .aspectFill, options: options, resultHandler: { [weak self] (result, _) in
                    guard let self = self else { return }
                    self.imageRequestID = nil
                    let newAlbum = AlbumModel(name: name ?? obj.localizedTitle!, count: obj.getPhotosCount(fetchOptions: self.fetchOptions), collection: obj, image: result ?? UIImage())
                    self.albums.append(newAlbum)
                    self.albums = self.albums.sorted(by: { (a1, a2) -> Bool in
                        return a1.name == "全部"
                    })
                    
                    self.selectedAlbum = self.albums.first
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    private func fetchAllPhotoAlbum() {
        requestPhotoAccessIfNeeded(PHPhotoLibrary.authorizationStatus())
        fetchAlbum(type: .smartAlbum, subtype: .smartAlbumUserLibrary)
    }
    
    private func fetchAlbums() {
        fetchAlbum(type: .album, subtype: .any)
    }
    
    private func requestPhotoAccessIfNeeded(_ status: PHAuthorizationStatus) {
        guard status == .notDetermined else {
            photoAssets = PHAsset.fetchAssets(with: fetchOptions)
            collectionView.reloadData()
            return
        }
        
        PHPhotoLibrary.requestAuthorization {_ in
            DispatchQueue.main.async {
                self.photoAssets = PHAsset.fetchAssets(with: self.fetchOptions)
                self.fetchAllPhotoAlbum()
                self.collectionView.reloadData()
            }
        }
    }
    
    private func getAssets(fromCollection collection: PHAssetCollection) -> PHFetchResult<PHAsset> {
        return PHAsset.fetchAssets(in: collection, options: fetchOptions)
    }
    
    private func showCamera() {
        let cameraPicer = UIImagePickerController()
        cameraPicer.sourceType = .camera
        cameraPicer.delegate = delegate
        self.present(cameraPicer, animated: true)
    }
    
    private func showCountLimitAlert() -> Bool {
        if selectedPhotoAssets.count >= selectedImageLimitCount {
            showImageCountLimitAlert?(self.view)
            return false
        }
        
        return true
    }
    
    private func showFormatInvalidAlert(asset: PHAsset) -> Bool {
        guard let fileName = asset.value(forKey: "filename") as? String,
              let fileExtension = fileName.split(separator: ".").last?.uppercased() else {
            return false
        }
        
        if !allowImageFormat.contains(String(fileExtension)) {
            showImageFormatInvalidAlert?(self.view)
            return false
        }
        
        return true
    }
    
    private func showSizeLimitAlert(asset: PHAsset) -> Bool {
        let resources = PHAssetResource.assetResources(for: asset)
        var sizeOnDisk: Int64? = 0
        if let resource = resources.first {
            let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong
            sizeOnDisk = Int64(bitPattern: UInt64(unsignedInt64!))
            if Units(bytes: sizeOnDisk!).megabytes > 20 {
                showImageSizeLimitAlert?(self.view)
                return false
            }
        }
        
        return true
    }
}

extension PHAssetCollection {
    func getPhotosCount(fetchOptions: PHFetchOptions?) -> Int {
        let options = fetchOptions ?? PHFetchOptions()
        let result = PHAsset.fetchAssets(in: self, options: options)
        return result.count
    }
}

extension ImagePickerViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoAssets.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as? CollectionViewCell else { fatalError() }
        if indexPath.item == 0 {
            cell.cameraView.isHidden = false
            cell.imgBackground.image = nil
        } else {
            cell.cameraView.isHidden = true
            cell.indexPath = indexPath
            cell.photoAsset = photoAssets.object(at: indexPath.item - 1)
            for view in cell.subviews {
                if view.tag != 0 {
                    view.removeFromSuperview()
                }
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let newCell = collectionView.cellForItem(at: indexPath) as? CollectionViewCell else { return }
        guard indexPath.item != 0 else {
            showCamera()
            return
        }
        let index = indexPath.item - 1
        let asset = photoAssets.object(at: index)
        if selectedPhotoAssets.contains(asset) {
            selectedPhotoAssets = selectedPhotoAssets.filter{ $0 != asset }
            for view in newCell.subviews {
                if view.tag == indexPath.item {
                    view.removeFromSuperview()
                }
            }
        } else {
            guard showCountLimitAlert(), showSizeLimitAlert(asset: asset), showFormatInvalidAlert(asset: asset) else { return }
            selectedPhotoAssets.append(asset)
            let selectedImage = UIImageView(frame: newCell.imgBackground.frame)
            selectedImage.tag = indexPath.item
            selectedImage.image = UIImage(named: "iconPhotoSelected32")
            selectedImage.contentMode = .center
            selectedImage.backgroundColor = UIColor(red: 19/255, green: 19/255, blue: 19/255, alpha: 0.7)
            newCell.addSubview(selectedImage)
        }
        
        countLabel.text = "\(selectedPhotoAssets.count)/\(selectedImageLimitCount)"
    }
    
}

extension ImagePickerViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? TableViewCell else { fatalError() }
        let album = albums[indexPath.row]
        cell.textLabel?.textColor = UIColor.white
        cell.nameLabel.text = album.name
        cell.countLabel.text = "\(album.count)"
        cell.imageImageView.image = album.image
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedAlbum! == albums[indexPath.row] {
            tableView.isHidden = !tableView.isHidden
            return
        }
        
        selectedAlbum = albums[indexPath.row]
        albumButton.setTitle(selectedAlbum?.name, for: .normal)
        albumButton.sizeToFit()
        photoAssets = getAssets(fromCollection: selectedAlbum!.collection)
        selectedPhotoAssets = []
        selectedImages = []
        collectionView?.reloadData()
        tableView.isHidden = !tableView.isHidden
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewWillLayoutSubviews()
    }
}

class AlbumModel {
    let name: String
    let count: Int
    let collection: PHAssetCollection
    let image: UIImage
    init(name: String, count: Int, collection: PHAssetCollection, image: UIImage) {
        self.name = name
        self.count = count
        self.collection = collection
        self.image = image
    }
    
    static func == (album1: AlbumModel, album2: AlbumModel) -> Bool {
        return album1.name == album2.name
    }
}
