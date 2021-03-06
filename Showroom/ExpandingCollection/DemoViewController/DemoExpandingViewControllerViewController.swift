import UIKit
import expanding_collection

class DemoExpandingViewController: ExpandingViewController {
  
  typealias ItemInfo = (imageName: String, title: String)
  fileprivate var cellsIsOpen = [Bool]()
  fileprivate let items: [ItemInfo] = [("item0", "Boston"),("item1", "New York"),("item2", "San Francisco"),("item3", "Washington")]
  
  @IBOutlet weak var pageLabel: UILabel!
}

// MARK: life cicle
extension DemoExpandingViewController {
  
  override func viewDidLoad() {
    itemSize = CGSize(width: 256, height: 460)
    super.viewDidLoad()
    
    registerCell()
    fillCellIsOpeenArry()
    addGestureToView(collectionView!)
    configureNavBar()
    
    MenuPopUpViewController.showPopup(on: self, url: "https://github.com/Ramotion/expanding-collection") { [weak self] in
      self?.navigationController?.dismiss(animated: true, completion: nil)
      self?.navigationController?.dismiss(animated: true, completion: nil)
    }
  }
  
  override open var shouldAutorotate: Bool {
    return false
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    ThingersTapViewController.showPopup(on: self)
  }
}

// MARK: Helpers 

extension DemoExpandingViewController {
  
  fileprivate func registerCell() {
    
    let nib = UINib(nibName: String(describing: DemoCollectionViewCell.self), bundle: nil)
    collectionView?.register(nib, forCellWithReuseIdentifier: String(describing: DemoCollectionViewCell.self))
  }
  
  fileprivate func fillCellIsOpeenArry() {
    for _ in items {
      cellsIsOpen.append(false)
    }
  }
  
  fileprivate func getViewController() -> ExpandingTableViewController {
    let storyboard = UIStoryboard(storyboard: .Main)
    let toViewController: DemoExpandingTableViewController = storyboard.instantiateViewController()
    return toViewController
  }
  
  fileprivate func configureNavBar() {
    navigationItem.leftBarButtonItem?.image = navigationItem.leftBarButtonItem?.image!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
  }
}

/// MARK: Gesture

extension DemoExpandingViewController {
  
  fileprivate func addGestureToView(_ toView: UIView) {
    let gestureUp = UISwipeGestureRecognizer(target: self, action: #selector(DemoExpandingViewController.swipeHandler(_:)))
    gestureUp.direction = .up
    
    let gestureDown = UISwipeGestureRecognizer(target: self, action: #selector(DemoExpandingViewController.swipeHandler(_:))) 
    gestureDown.direction = .down
    
    toView.addGestureRecognizer(gestureUp)
    toView.addGestureRecognizer(gestureDown)
  }
  
  @objc func swipeHandler(_ sender: UISwipeGestureRecognizer) {
    let indexPath = IndexPath(row: currentIndex, section: 0)
    guard let cell  = collectionView?.cellForItem(at: indexPath) as? DemoCollectionViewCell else { return }
    // double swipe Up transition
    if cell.isOpened == true && sender.direction == .up {
      pushToViewController(getViewController())
      
      if let rightButton = navigationItem.rightBarButtonItem as? AnimatingBarButton {
        rightButton.animationSelected(true)
      }
    }
    
    let open = sender.direction == .up ? true : false
    cell.cellIsOpen(open)
    cellsIsOpen[(indexPath as NSIndexPath).row] = cell.isOpened
  }
}

// MARK: UIScrollViewDelegate 

extension DemoExpandingViewController {
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    pageLabel.text = "\(currentIndex+1)/\(items.count)"
  }
}

// MARK: UICollectionViewDataSource

extension DemoExpandingViewController {
  
  override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    super.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
    guard let cell = cell as? DemoCollectionViewCell else { return }
    
    let index = (indexPath as NSIndexPath).row % items.count
    let info = items[index]
    cell.backgroundImageView?.image = UIImage(named: info.imageName)
    cell.customTitle.text = info.title
    cell.cellIsOpen(cellsIsOpen[index], animated: false)
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: IndexPath) {
    guard let cell = collectionView.cellForItem(at: indexPath) as? DemoCollectionViewCell
      , currentIndex == (indexPath as NSIndexPath).row else { return }
    
    if cell.isOpened == false {
      cell.cellIsOpen(true)
    } else {
      pushToViewController(getViewController())
      
      if let rightButton = navigationItem.rightBarButtonItem as? AnimatingBarButton {
        rightButton.animationSelected(true)
      }
    }
  }
}

// MARK: UICollectionViewDataSource
extension DemoExpandingViewController {
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return items.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: DemoCollectionViewCell.self), for: indexPath)
  }
}
