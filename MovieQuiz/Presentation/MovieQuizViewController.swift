import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    struct ViewModel {
      let image: UIImage
      let question: String
      let questionNumber: String
    }
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var yesButton: UIButton!
    @IBOutlet private var noButton: UIButton!
    
    private var correctAnswers = 0
    
    private var currentQuestionIndex = 0
    private let questionsAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol = QuestionFactory()
    private var currentQuestion: QuizQuestion?
    private var alertPresenter: AlertPresenter?
    private var statisticService: StatisticService = StatisticService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.alertPresenter = AlertPresenter(viewController: self)
        let questionFactory = QuestionFactory()
        questionFactory.setup(delegate: self)
        self.questionFactory = questionFactory
        questionFactory.requestNextQuestion()
        
        imageView.layer.cornerRadius = 20
        yesButton.layer.cornerRadius = 15
        noButton.layer.cornerRadius = 15
    }
    
    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else { return }
        currentQuestion = question
        let viewModel = convert(model: question)
        show(quiz: viewModel)
        }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else { return }
        let givenAnswer = true
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else { return }
        let givenAnswer = false
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    private func changeButtonsCondition(isEnabled: Bool) {
        yesButton.isEnabled = isEnabled
        noButton.isEnabled = isEnabled
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        self.changeButtonsCondition(isEnabled: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
            self.changeButtonsCondition(isEnabled: true)
        }
    }
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let questionStep: QuizStepViewModel = QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
        return questionStep
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func showNextQuestionOrResults() {
        imageView.layer.borderWidth = 0
        statisticService.store(correct: correctAnswers, total: questionsAmount)
        if currentQuestionIndex == questionsAmount - 1 {
            statisticService.gamesCount += 1
            statisticService.correctAnswers += correctAnswers
            let gamesPlayed: Int = statisticService.gamesCount
            let totalAccuracy: Double = statisticService.totalAccuracy
            let bestScore: Int = statisticService.bestGame.correct
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yy HH:mm"
            let formattedDate = dateFormatter.string(from: statisticService.bestGame.date)
            
            let message = """
                            Ваш результат: \(correctAnswers)/\(questionsAmount)
                            Количество сыгранных квизов: \(gamesPlayed)
                            Рекорд: \(bestScore)/10 (\(formattedDate))
                            Средняя точность: \(String(format: "%.2f", totalAccuracy))%
                            """
            
            let alertModel = AlertModel(
                            title: "Этот раунд окончен",
                            message: message,
                            buttonText: "Сыграть ещё раз"
                ) { [weak self] in
                    guard let self = self else { return }
            
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            self.questionFactory.requestNextQuestion()
                }
                
            alertPresenter?.showAlert(model: alertModel)
        } else {
            currentQuestionIndex += 1
            self.questionFactory.requestNextQuestion()
        }
    }
}
