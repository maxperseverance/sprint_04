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
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
//    private let questionsAmount: Int = 10
    private let presenter = MovieQuizPresenter()
    private var correctAnswers = 0
//    private var currentQuestionIndex = 0
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertPresenter: AlertPresenter?
    private var statisticService: StatisticService = StatisticService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.layer.cornerRadius = 20
        yesButton.layer.cornerRadius = 15
        noButton.layer.cornerRadius = 15
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        statisticService = StatisticService()

        showLoadingIndicator()
        questionFactory?.loadData()
        
        self.alertPresenter = AlertPresenter(viewController: self)
    }
    
    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else { return }
        currentQuestion = question
        let viewModel = presenter.convert(model: question)
        show(quiz: viewModel)
        }
    
    func didLoadDataFromServer() {
        activityIndicator.isHidden = true
        questionFactory?.requestNextQuestion()
    }

    func didFailToLoadData(with error: Error) {
//        showNetworkError(message: error.localizedDescription)
        showNetworkError(message: "Потеряно соединение с сервером.\nПожалуйста, попробуйте еще раз.")
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
    
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    private func showNetworkError(message: String) {
//        hideLoadingIndicator()
        
        let model = AlertModel(title: "Ошибка",
                               message: message,
                               buttonText: "Попробовать еще раз") { [weak self] in
            guard let self = self else { return }
            
            self.presenter.resetQuestionIndex()
            self.correctAnswers = 0
            
            self.questionFactory?.requestNextQuestion()
        }
        
        alertPresenter?.showAlert(model: model)
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
    
//    private func convert(model: QuizQuestion) -> QuizStepViewModel {
//        let questionStep: QuizStepViewModel = QuizStepViewModel(
//            image: UIImage(data: model.image) ?? UIImage(),
//            question: model.text,
//            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
//        return questionStep
//    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func showNextQuestionOrResults() {
        imageView.layer.borderWidth = 0
        statisticService.store(correct: correctAnswers, total: presenter.questionsAmount)
        if self.presenter.isLastQuestion() {
            statisticService.gamesCount += 1
            statisticService.correctAnswers += correctAnswers
            let gamesPlayed: Int = statisticService.gamesCount
            let totalAccuracy: Double = statisticService.totalAccuracy
            let bestScore: Int = statisticService.bestGame.correct
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yy HH:mm"
            let formattedDate = dateFormatter.string(from: statisticService.bestGame.date)
            
            let message = """
                            Ваш результат: \(correctAnswers)/\(presenter.questionsAmount)
                            Количество сыгранных квизов: \(gamesPlayed)
                            Рекорд: \(bestScore)/10 (\(formattedDate))
                            Средняя точность: \(String(format: "%.2f", totalAccuracy))%
                            """
            
            let alertModel = AlertModel(
                            title: "Этот раунд окончен!",
                            message: message,
                            buttonText: "Сыграть ещё раз"
                ) { [weak self] in
                    guard let self = self else { return }
            
            self.presenter.resetQuestionIndex()
            self.correctAnswers = 0
            self.questionFactory?.requestNextQuestion()
                }
                
            alertPresenter?.showAlert(model: alertModel)
        } else {
            self.presenter.switchToNextQuestion()
            self.questionFactory?.requestNextQuestion()
        }
    }
}
