import Foundation

final class StatisticService: StatisticServiceProtocol {
    private let storage: UserDefaults = .standard
    
    var correctAnswers: Int {
        get {
            UserDefaults.standard.integer(forKey: "correctAnswers")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "correctAnswers")
        }
    }
    
    private enum Keys: String {
        case correct
        case bestGame
        case gamesCount
    }
    
    var gamesCount: Int {
        get {
            storage.integer(forKey: Keys.gamesCount.rawValue)
        }
        set {
            storage.set(newValue, forKey: Keys.gamesCount.rawValue)
        }
    }
    
    var bestGame: GameResult {
        get {
            let correct: Int = storage.integer(forKey: "bestGameCorrect")
            let total: Int = storage.integer(forKey: "bestGameTotal")
            let date: Date = storage.object(forKey: "bestGameDate") as? Date ?? Date()
            return GameResult(correct: correct, total: total, date: date)
        }
        set {
            storage.set(newValue.correct, forKey: "bestGameCorrect")
            storage.set(newValue.total, forKey: "bestGameTotal")
            storage.set(newValue.date, forKey: "bestGameDate")
        }
    }
    
    var totalAccuracy: Double {
        if gamesCount != 0 {
            Double(correctAnswers) / Double((10 * gamesCount)) * 100
        } else {
            0.0
        }
    }
    
    func store(correct count: Int, total amount: Int) {
        if count > storage.integer(forKey: "bestGameCorrect") {
            let newBestGame: GameResult = GameResult(correct: count, total: amount, date: Date())
            bestGame = newBestGame
        }
    }
}
