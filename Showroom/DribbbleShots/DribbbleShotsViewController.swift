import UIKit
import OAuthSwift
import Nuke
import RxSwift
import Firebase
import MBProgressHUD

final class DribbbleShotsViewController: UIViewController {
    
    typealias ShotAndSended = (shot: Shot, sended: Bool)
    
    enum Item {
        case shot(ShotAndSended)
        case wireframe
    }
    
    fileprivate let networkingManager: NetworkingManager
    fileprivate let userSignal: Observable<User>
    fileprivate let dribbbleShotsSignal: Observable<[Shot]>
    
    fileprivate let reloadData = Variable<[Item]>([.wireframe, .wireframe, .wireframe, .wireframe])

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var backgroundView: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        let network = NetworkingManager()
        self.networkingManager = network
        self.userSignal = network.fetchDribbbleUser()
        
        self.dribbbleShotsSignal = network.fetchDribbbleShots()
            .catchErrorJustReturn([])
            .map { $0.filter { shot in shot.animated } }
        
        super.init(coder: aDecoder)
    }
}

// MARK: Life Cycle
extension DribbbleShotsViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // customize nav bar
        title = "Dribbble Shots"
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneHandler))
        navigationItem.leftBarButtonItem = doneButton

        // customze collection
        collectionView.register(DribbbleShotCell.self)
        let margins = collectionView.layoutMargins.left + collectionView.layoutMargins.right
        let itemWidth = (UIScreen.main.bounds.size.width - margins) / 2 - 14
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = CGSize(width: itemWidth, height: itemWidth)
        collectionView.backgroundView = backgroundView
        collectionView.backgroundView?.isHidden = true

        fetchData(userSignal: userSignal, dribbbleShotsSignal: dribbbleShotsSignal)
        
        let reloadDataSignal = reloadData.asObservable()
        reloadDataSignal
            .bind(to: collectionView.rx.items(cellIdentifier: "Shot", cellType: DribbbleShotCell.self)) { row, element, cell in
                switch element {
                case .shot(let shot, let sended):
                    cell.nameLabel.isHidden = false
                    cell.backgroundColor = UIColor.white
                    cell.nameLabel.text = shot.title
                    if let url = shot.imageUrl { Manager.shared.loadImage(with: url, into: cell.imageView) }
                    cell.imageView.alpha = sended ? 0.3 : 1
                case .wireframe:
                    cell.backgroundColor = UIColor.gray
                    cell.nameLabel.isHidden = true
                }
            }
            .disposed(by: rx.disposeBag)
        
        reloadDataSignal.subscribe { [weak self] in
            self?.collectionView.backgroundView?.isHidden = ($0.element?.count ?? 0) != 0
        }
        .disposed(by: rx.disposeBag)
        
        // MARK: Item did select
        collectionView.rx
            .modelSelected(Item.self)
            .flatMap({ item -> Observable<Shot> in
                switch item {
                case .shot(let shot, let sended): return sended ? Observable.empty() : Observable.just(shot)
                case .wireframe: return Observable.empty()
                }
                
            })
            .withLatestFrom(userSignal, resultSelector: { return ($0, $1) })
            .flatMap { param -> Observable<(Shot, User, String)> in
                return UIAlertController.confirmation(message: "Do you want send this shot?")
                    .withLatestFrom(Observable.just(param)) { message, shotInfo in (shotInfo.0, shotInfo.1, message) }
            }
            .flatMap { [weak self] (shot, user, message) -> Observable<Void> in
                if let `self` = self { MBProgressHUD.showAdded(to: self.view, animated: true) }
                return Firestore.firestore().rx.save(shot: shot, user: user, message: message)
            }
            .subscribe { [weak self] in
                guard let `self` = self else { return }
                MBProgressHUD.hide(for: self.view, animated: true)
                switch $0 {
                case .completed: break
                case .error: UIAlertController.show(message: "Can't send shot!")
                case .next: self.fetchData(userSignal: self.userSignal, dribbbleShotsSignal: self.dribbbleShotsSignal)
                }
            }
            .disposed(by: rx.disposeBag)
    }
    
    // MARK: Actions
    @objc func doneHandler() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: Helpers
private extension DribbbleShotsViewController {
    
    func fetchData(userSignal: Observable<User>, dribbbleShotsSignal: Observable<[Shot]>) {
        
        let sendedShotsSignal = userSignal.flatMap { return Firestore.firestore().rx.fetchShots(from: $0) }
            .catchErrorJustReturn([])
        
        Observable.zip(dribbbleShotsSignal, sendedShotsSignal) { return ($0, $1) }
            .map { (dribbbleShots, sendedShots) -> [(Shot, Bool)] in // shot, selected
                let sendedShotIds = sendedShots.map { $0.id }
                return dribbbleShots.map { ($0, sendedShotIds.contains($0.id)) }
            }
            .subscribe({ [weak self] in
                if let items = $0.element {
                    self?.reloadData.value = items.map { Item.shot((shot: $0.0, sended: $0.1)) }
                }
            })
            .disposed(by: rx.disposeBag)
    }
}
