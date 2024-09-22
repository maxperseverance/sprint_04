import UIKit

final class AlertPresenter {
    private weak var viewController: UIViewController?
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func showAlert(model: AlertModel) {
        let alert = UIAlertController(
            title: model.title,
            message: model.message,
            preferredStyle: .alert)
        let action = UIAlertAction(
            title: model.buttonText,
            style: .default)
        { _ in model.completion() }
        
        if alert.title == "Этот раунд окончен!" {
            alert.view.accessibilityIdentifier = "GameResults"
        } else {
            alert.view.accessibilityIdentifier = "Error"
        }
        
        alert.addAction(action)
        viewController?.present(alert, animated: true, completion: nil)
    }
}
