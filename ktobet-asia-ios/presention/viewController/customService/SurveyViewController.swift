import UIKit
import RxSwift
import RxCocoa
import SharedBu

class SurveyViewController: UIViewController {
    var viewModel: SurveyViewModel!
    var surveyInfo: Survey! {
        didSet {
            titleLabel.text = surveyInfo.heading
            subTitleLabel.text = surveyInfo.description_
            tableView.layoutTableHeaderView()
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
     
    private var disposeBag = DisposeBag()
    var dataSource: [SurveyQuestion_] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    private func initUI() {
        tableView.estimatedRowHeight = 48.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 86.0
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension SurveyViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let questionSection: SurveyQuestion_ = dataSource[section]
        return tableView.dequeueReusableCell(withIdentifier: "ServeyHeaderViewCell", cellType: ServeyHeaderViewCell.self).configure(questionSection).contentView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let questionSection: SurveyQuestion_ = dataSource[section]
        let surveyQuestionType: SurveyQuestion_.SurveyQuestionType = questionSection.surveyQuestionType
        switch surveyQuestionType {
        case .simpleoption:
            return 1
        case .multipleoption:
            return questionSection.surveyQuestionOptions.count
        case .textfield:
            return 1
        default:
            return questionSection.surveyQuestionOptions.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        let surveyQuestionType: SurveyQuestion_.SurveyQuestionType = dataSource[section].surveyQuestionType
        var cell: UITableViewCell
        switch surveyQuestionType {
        case .simpleoption:
            cell = tableView.dequeueReusableCell(withIdentifier: "DropdownOptionCell", cellType: DropdownOptionCell.self).configure(dataSource[section].surveyQuestionOptions, nil) { [weak self] (selected) in
                self?.answer(simple: selected, indexPath: indexPath)
            }
            drawDivider(cell)
        case .multipleoption:
            let option: SurveyQuestion_.SurveyQuestionOption = dataSource[section].surveyQuestionOptions[row]
            cell = tableView.dequeueReusableCell(withIdentifier: "MultipleOptionCell", cellType: MultipleOptionCell.self).configure(option, rowIsSelected(option: option, indexPath: indexPath))
            drawDivider(cell)
        case .textfield:
            cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", cellType: TextFieldCell.self).configure(viewModel: viewModel) { [weak self] (text) in
                self?.answer(textField: text, indexPath: indexPath)
            }
        default:
            cell = UITableViewCell()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        let option: SurveyQuestion_.SurveyQuestionOption = dataSource[section].surveyQuestionOptions[row]
        let surveyQuestionType: SurveyQuestion_.SurveyQuestionType = dataSource[section].surveyQuestionType
        switch surveyQuestionType {
        case .simpleoption:
            answer(simple: option, indexPath: indexPath)
        case .multipleoption:
            answer(multiple: option, indexPath: indexPath)
            let section = indexPath.section
            tableView.reloadSections(IndexSet(integersIn: section...section), with: .none)
            break
        case .textfield:
            break
        default:
            break
        }
    }
    
    private func rowIsSelected(option: SurveyQuestion_.SurveyQuestionOption, indexPath: IndexPath) -> Bool {
        let section = indexPath.section
        return viewModel.cachedSurveyAnswers?[section].isOptionSelected(option) ?? false
    }
    
    private func answer(sigle option: SurveyQuestion_.SurveyQuestionOption, indexPath: IndexPath) {
        let section = indexPath.section
        let answerItem = viewModel.cachedSurveyAnswers?[section]
        if rowIsSelected(option: option, indexPath: indexPath) {
            answerItem?.options.removeAll()
        } else {
            answerItem?.options.removeAll()
            answerItem?.addAnswer(option)
        }
        viewModel.answerUpdate()
    }
    
    private func answer(simple option: SurveyQuestion_.SurveyQuestionOption, indexPath: IndexPath) {
        let section = indexPath.section
        let answerItem = viewModel.cachedSurveyAnswers?[section]
        answerItem?.options.removeAll()
        answerItem?.addAnswer(option)
        viewModel.answerUpdate()
    }
    
    private func answer(multiple option: SurveyQuestion_.SurveyQuestionOption, indexPath: IndexPath) {
        let section = indexPath.section
        let answerItem = viewModel.cachedSurveyAnswers?[section]
        if rowIsSelected(option: option, indexPath: indexPath) {
            answerItem?.removeAnswer(option)
        } else {
            answerItem?.addAnswer(option)
        }
        viewModel.answerUpdate()
    }
    
    private func answer(textField text: String, indexPath: IndexPath) {
        let section = indexPath.section
        let answerItem = viewModel.cachedSurveyAnswers?[section]
        if let question = answerItem?.question {
            if text.isEmpty {
                answerItem?.options.removeAll()
            } else {
                let option = SurveyQuestion_.SurveyQuestionOption(optionId: "", questionId: question.questionId, enable: false, isOther: false, values: text)
                answerItem?.addAnswer(option)
            }
        }
        viewModel.answerUpdate()
    }
    
    private func drawDivider(_ cell: UITableViewCell) {
        cell.addBorder(.top)
        cell.addBorder(.bottom)
    }
    
}

class ServeyHeaderViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    func configure(_ item: SurveyQuestion_) -> Self {
        titleLabel.text = item.description_
        messageLabel.text = item.isRequired ? Localize.string("common_field_must_fill_2") : nil
        return self
    }
}

class DropdownOptionCell: UITableViewCell {
    @IBOutlet weak var optionDropDown: DropDownInputText!
    
    func configure(_ item: [SurveyQuestion_.SurveyQuestionOption],
                   _ theSelected: SurveyQuestion_.SurveyQuestionOption?,
                   _ callback: ((SurveyQuestion_.SurveyQuestionOption) -> ())? = nil) -> Self {
        self.selectionStyle = .none
        optionDropDown.customizeBackgroundColor = (.backgroundListCodGray2, .backgroundListCodGray2)
        optionDropDown.optionArray = item.map({$0.values})
        if let selected = theSelected {
            optionDropDown.setContent(selected.values)
        } else {
            optionDropDown.setContent(Localize.string("common_please_select"))
        }
        optionDropDown.isSearchEnable = false
        optionDropDown.arrowSize = 15.0
        optionDropDown.arrowSolid = .filled
        optionDropDown.didSelect(completion: { (selectedText, index , id) in
            let option = item[index]
            callback?(option)
        })
        return self
    }
}

class SimpleOptionCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var icon: UIImageView!
    
    func configure(_ item: SurveyQuestion_.SurveyQuestionOption, _ isSelected: Bool) -> Self {
        self.selectionStyle = .none
        titleLabel.text = item.values
        icon.image = isSelected ? UIImage(named: "iconSingleSelectionSelected24") : UIImage(named: "iconSingleSelectionEmpty24")
        return self
    }
}

class MultipleOptionCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var icon: UIImageView!
    
    func configure(_ item: SurveyQuestion_.SurveyQuestionOption, _ isSelected: Bool) -> Self {
        self.selectionStyle = .none
        titleLabel.text = item.values
        icon.image = isSelected ? UIImage(named: "iconDoubleSelectionSelected24") : UIImage(named: "iconDoubleSelectionEmpty24")
        return self
    }
}

class TextFieldCell: UITableViewCell, UITextViewDelegate {
    @IBOutlet weak var textView: UITextView!
    private var viewModel: SurveyViewModel!
    var callback: ((String) -> ())?
    
    func configure(viewModel: SurveyViewModel, _ callback: ((String) -> ())? = nil) -> Self {
        self.selectionStyle = .none
        self.textView.delegate = self
        self.textView.text = Localize.string("customerservice_offline_survey_hint")
        self.textView.textColor = UIColor.textPrimaryDustyGray
        self.textView.textContainer.lineFragmentPadding = 0
        self.textView.textContainerInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        self.viewModel = viewModel
        self.callback = callback
        return self
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.textPrimaryDustyGray {
            textView.text = nil
            textView.textColor = UIColor.whiteFull
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        callback?(textView.text)
        if textView.text.isEmpty {
            textView.text = Localize.string("customerservice_offline_survey_hint")
            textView.textColor = UIColor.textPrimaryDustyGray
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let countOfWords = textView.text.count - range.length + text.count
        
        return isMessageLengthValid(countOfWords)
    }
    
    private func isMessageLengthValid(_ countOfWords: Int) -> Bool {
        let maxLength = viewModel.getTextFieldMaxLengthByLocale()
        return countOfWords <= maxLength
    }
}
