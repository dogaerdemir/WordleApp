//
//  WordleViewModel.swift
//  WordleApp
//
//  Created by Doğa Erdemir on 15.10.2025.
//

import Foundation
import Combine

@MainActor
final class WordleViewModel: ObservableObject {
    @Published var board: [[LetterBox]]
    @Published var currentRow = 0
    @Published var currentCol = 0
    @Published var targetWord: String = ""
    @Published var gameOver = false
    @Published var showTimeUpAlert = false
    @Published var invalidWordAlert = false
    @Published var timeRemaining: Int?
    @Published var eliminatedLetters: Set<String> = []
    
    private var timer: AnyCancellable?
    private let settings: GameSettings
    private let words: [String]
    private let normalizedWords: Set<String>
    
    init(settings: GameSettings, words: [String], startTimerImmediately: Bool = true) {
        self.settings = settings
        self.words = words
        self.board = Array(repeating: Array(repeating: LetterBox(), count: settings.wordLength), count: settings.guessLimit)
        self.targetWord = words.filter { $0.count == settings.wordLength }.randomElement()?.uppercased() ?? "APPLE"
        self.normalizedWords = Set(words.map { WordleViewModel.normalize($0) })
        if startTimerImmediately, settings.hasTimeLimit {
            startTimer(minutes: settings.timeLimit)
        }
    }
    
    private func startTimer(minutes: Int) {
        timeRemaining = minutes * 60
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let remaining = self.timeRemaining else { return }
                if remaining > 0 {
                    self.timeRemaining = remaining - 1
                } else {
                    self.gameOver = true
                    self.showTimeUpAlert = true
                    self.timer?.cancel()
                }
            }
    }
    
    private static func normalize(_ s: String) -> String {
        let lowered = s.lowercased(with: Locale(identifier: "tr_TR"))
        let noMarks = lowered.folding(options: .diacriticInsensitive, locale: Locale(identifier: "tr_TR"))
        return noMarks.precomposedStringWithCanonicalMapping
    }
    
    func formattedTime() -> String {
        guard let timeRemaining else { return "" }
        return String(format: "%d:%02d", timeRemaining / 60, timeRemaining % 60)
    }
    
    func addLetter(_ letter: String) {
        guard !gameOver, currentCol < settings.wordLength else { return }
        board[currentRow][currentCol].character = letter.uppercased()
        currentCol += 1
    }
    
    func removeLetter() {
        guard currentCol > 0 else { return }
        currentCol -= 1
        board[currentRow][currentCol].character = ""
    }
    
    func submitGuess() {
        guard currentCol == settings.wordLength else { return }
        
        let guessRaw = board[currentRow].map { $0.character }.joined()
        let guess = WordleViewModel.normalize(guessRaw)
        guard normalizedWords.contains(guess) else {
            invalidWordAlert = true
            return
        }
        
        let result = evaluateGuess(guess.uppercased())
        for i in 0..<settings.wordLength {
            board[currentRow][i].result = result[i]
            
            if settings.disableLetters && result[i] == .wrong {
                eliminatedLetters.insert(board[currentRow][i].character)
            }
        }
        
        if guess.uppercased() == targetWord {
            gameOver = true
            timer?.cancel()
        } else {
            currentRow += 1
            currentCol = 0
            if currentRow == settings.guessLimit {
                gameOver = true
                timer?.cancel()
            }
        }
    }
    
    func evaluateGuess(_ guess: String) -> [LetterResult] {
        var result = Array(repeating: LetterResult.wrong, count: settings.wordLength)
        var targetArray = Array(targetWord)
        let guessArray = Array(guess)
        
        for i in 0..<settings.wordLength {
            if guessArray[i] == targetArray[i] {
                result[i] = .correct
                targetArray[i] = "*"
            }
        }
        
        for i in 0..<settings.wordLength {
            if result[i] == .correct { continue }
            if let idx = targetArray.firstIndex(of: guessArray[i]) {
                result[i] = .misplaced
                targetArray[idx] = "*"
            }
        }
        
        return result
    }
    
    deinit {
        timer?.cancel()
    }
}
