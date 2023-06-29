import RxCocoa
import RxSwift
import SharedBu
import UIKit

class ExitSurveyViewController: CommonViewController {
  var barButtonItems: [UIBarButtonItem] = []
  var viewModel: SurveyViewModel!
  var roomId: RoomId?
  var surveyInfo: Survey? {
    didSet {
      self.survey = surveyInfo
    }
  }

  @IBOutlet weak var containView: UIView!
  @IBOutlet weak var completeBtn: UIButton!
  private lazy var surveyVC: SurveyViewController = {
    var viewController = self.storyboard?
      .instantiateViewController(withIdentifier: "SurveyViewController") as! SurveyViewController
    viewController.viewModel = self.viewModel
    return viewController
  }()

  private var survey: Survey?
  private var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    initUI()
    dataBinding()
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func initUI() {
    self.addChildViewController(self.surveyVC, inner: self.containView)
  }

  private func dataBinding() {
    viewModel.getExitSurvey(roomId: roomId!)
      .subscribe(onFailure: { [weak self] in
        self?.handleErrors($0)
      })
      .disposed(by: disposeBag)

    viewModel.cachedSurvey.compactMap({ $0 }).subscribe(onNext: { [weak self] in
      guard let self else { return }
      self.surveyInfo = $0
      self.surveyVC.surveyInfo = $0
      self.surveyVC.dataSource = $0.surveyQuestions
    }).disposed(by: disposeBag)

    Observable.combineLatest(viewModel.isAnswersValid, networkConnectRelay.asObservable()).map({ $0 && $1 })
      .bind(to: completeBtn.rx.isValid).disposed(by: disposeBag)

    completeBtn.rx.touchUpInside
      .do(onNext: { [weak self] in
        self?.completeBtn.isEnabled = false
      }).flatMap({ [unowned self] _ -> Observable<Void> in
        guard let roomId = self.roomId, let survey = self.survey else {
          return Observable.error(KTOError.EmptyData)
        }
        return self.viewModel.answerExitSurvey(roomId: roomId, survey: survey).andThen(.just(()))
      }).catch({ [weak self] in
        self?.handleErrors($0)
        self?.completeBtn.isEnabled = true
        return Observable.error($0)
      }).retry()
      .subscribe(onNext: { [unowned self] in
        self.popThenToast()
      }).disposed(by: disposeBag)
  }

  private func popThenToast() {
    CustomServicePresenter.shared.closeService()
    showToast(Localize.string("customerservice_offline_survey_confirm_title"), barImg: .success)
  }
}

extension ExitSurveyViewController: BarButtonItemable {
  func pressedLeftBarButtonItems(_: UIBarButtonItem) {
    CustomServicePresenter.shared.closeService()
  }

  func pressedRightBarButtonItems(_: UIBarButtonItem) {
    CustomServicePresenter.shared.closeService()
  }
}
