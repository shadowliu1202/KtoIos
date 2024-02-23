import sharedbu
import UIKit

protocol ProductNavigations {
  var productType: ProductType { get }
}

class CasinoNavigation: UINavigationController, ProductNavigations {
  var productType: ProductType = .casino
}

class SlotNavigation: UINavigationController, ProductNavigations {
  var productType: ProductType = .slot
}

class NumbergameNavigation: UINavigationController, ProductNavigations {
  var productType: ProductType = .numberGame
}

class P2PNavigation: UINavigationController, ProductNavigations {
  var productType: ProductType = .p2P
}

class ArcadeNavigation: UINavigationController, ProductNavigations {
  var productType: ProductType = .arcade
}
