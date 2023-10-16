import RxCocoa
import RxSwift
import sharedbu
import UIKit

class PrechatServeyViewController: CommonViewController {
  var barButtonItems: [UIBarButtonItem] = []
  var viewModel: SurveyViewModel!
  var csViewModel: CustomerServiceViewModel!
  var surveyInfo: Survey! {
    didSet {
      self.survey = surveyInfo
      self.skillId = surveyInfo.csSkillId
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

  private var survey: Survey!
  private var skillId: SkillId?
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
    networkConnectRelay.bind(onNext: { [weak self] in
      self?.barButtonItems.first(where: { $0.tag == skipBarBtnId })?.isEnabled = $0
    }).disposed(by: disposeBag)
    viewModel.cachedSurvey.subscribe(onNext: { [weak self] in
      guard let self else { return }
      self.surveyInfo = $0
      self.surveyVC.surveyInfo = $0
      self.surveyVC.dataSource = $0?.surveyQuestions ?? []
    }).disposed(by: disposeBag)

    Observable.combineLatest(viewModel.isAnswersValid, networkConnectRelay.asObservable()).map({ $0 && $1 })
      .bind(to: completeBtn.rx.isValid).disposed(by: disposeBag)

    completeBtn.rx.touchUpInside
      .do(onNext: { [weak self] in
        self?.completeBtn.isEnabled = false
      }).flatMap({ [unowned self] _ -> Observable<Void> in
        guard
          let question = viewModel.cachedSurveyAnswers?.map({ $0.question }),
          let options = viewModel.cachedSurveyAnswers?.map({ Array($0.options) })
        else { return Observable.error(KTOError.EmptyData) }
        return self.setupAnswer(
          survey: self.survey,
          surveyAnswers: Dictionary(uniqueKeysWithValues: zip(question, options))).andThen(.just(()))
      }).catch({ [weak self] in
        self?.handleErrors($0)
        self?.completeBtn.isEnabled = true
        return Observable.error($0)
      }).retry()
      .subscribe(onNext: { [unowned self] in
        CustomServicePresenter.shared.switchToCalling(svViewModel: viewModel)
      }).disposed(by: disposeBag)
  }

  private func setupAnswer(
    survey: Survey,
    surveyAnswers: [SurveyQuestion_: [SurveyQuestion_.SurveyQuestionOption]])
    -> Completable
  {
    Completable.create { [unowned self] completable in
      self.csViewModel.setupSurveyAnswer(answers: SurveyAnswers(
        csSkillId: survey.csSkillId,
        surveyId: survey.surveyId,
        answers: surveyAnswers,
        surveyType: survey.surveyType))
      completable(.completed)
      return Disposables.create()
    }
  }
}

extension PrechatServeyViewController: BarButtonItemable {
  func pressedLeftBarButtonItems(_: UIBarButtonItem) {
    CustomServicePresenter.shared.resetStatus()
  }

  func pressedRightBarButtonItems(_: UIBarButtonItem) {
    CustomServicePresenter.shared.switchToCalling(svViewModel: viewModel)
  }
}
