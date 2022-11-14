import UIKit

@propertyWrapper
struct Storyboard<ViewController> {
    let name: String
    private (set) var wrappedValue: ViewController
    
    init(name: String) {
        self.name = name
        
        let storyboard = UIStoryboard(name: name, bundle: nil)
        
        guard let controller = storyboard.instantiateViewController(withIdentifier: "\(ViewController.self)") as? ViewController
        else {
            fatalError("There is some error about create viewController at \(name)")
        }
        
        wrappedValue = controller
    }
}
