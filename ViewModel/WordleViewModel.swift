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
    
    init(settings: GameSettings, words: [String]) {
        self.settings = settings
        self.words = words
        self.board = Array(repeating: Array(repeating: LetterBox(), count: settings.wordLength),
                           count: settings.guessLimit)
        self.targetWord = words.filter { $0.count == settings.wordLength }.randomElement()?.uppercased() ?? "APPLE"
        
        if settings.hasTimeLimit {
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
        
        let guess = board[currentRow].map { $0.character }.joined().lowercased()
        guard words.contains(guess) else {
            invalidWordAlert = true
            return
        }
        
        let result = evaluateGuess(guess.uppercased())
        for i in 0..<settings.wordLength {
            board[currentRow][i].result = result[i]
            if settings.disableEliminatedLetters && result[i] == .wrong {
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
    
    private func evaluateGuess(_ guess: String) -> [LetterResult] {
        var result = Array(repeating: LetterResult.wrong, count: settings.wordLength)
        let targetArray = Array(targetWord)
        let guessArray = Array(guess)
        
        for i in 0..<settings.wordLength {
            if guessArray[i] == targetArray[i] {
                result[i] = .correct
            } else if targetArray.contains(guessArray[i]) {
                result[i] = .misplaced
            }
        }
        
        return result
    }
}