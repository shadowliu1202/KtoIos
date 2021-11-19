import UIKit
import RxSwift
import RxCocoa
import SharedBu

class PrechatServeyViewController: UIViewController {
    var barButtonItems: [UIBarButtonItem] = []
    var viewModel: SurveyViewModel!
    var surveyInfo: SurveyInformation! {
        didSet {
            self.survey = surveyInfo.survey
            self.skillId = surveyInfo.skillId
        }
    }
    
    @IBOutlet weak var containView: UIView!
    @IBOutlet weak var completeBtn: UIButton!
    
    private lazy var surveyVC: SurveyViewController = {
        var viewController = self.storyboard?.instantiateViewController(withIdentifier: "SurveyViewController") as! SurveyViewController
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
        print("\(type(of: self)) deinit")
    }
    
    private func initUI() {
        self.addChildViewController(self.surveyVC, inner: self.containView)
    }
    
    private func dataBinding() {
        viewModel.cachedSurvey.subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            self.surveyInfo = $0
            self.surveyVC.surveyInfo = $0
            self.surveyVC.dataSource = $0?.survey?.surveyQuestions ?? []
        }).disposed(by: disposeBag)
        
        viewModel.isAnswersValid.bind(to: completeBtn.rx.isValid).disposed(by: disposeBag)
        
        completeBtn.rx.touchUpInside
            .do(onNext: { [weak self] in
                self?.completeBtn.isEnabled = false
            }).flatMap({ [unowned self] _ in
                self.viewModel.answerPreChatSurvey(survey: self.survey)
            }).catchError({[weak self] in
                self?.handleErrors($0)
                self?.completeBtn.isEnabled = true
                return Observable.error($0)
            }).retry()
            .subscribe(onNext: { [unowned self] (connectId) in
                CustomService.switchToCalling(skillID: self.skillId, connectId: connectId)
            }).disposed(by: disposeBag)
    }
    
}

extension PrechatServeyViewController: BarButtonItemable {
    func pressedLeftBarButtonItems(_ sender: UIBarButtonItem) {
        CustomService.close()
    }
    func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
        CustomService.switchToCalling(skillID: self.skillId, connectId: nil)
    }
}


