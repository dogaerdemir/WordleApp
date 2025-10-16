//
//  GameSettings.swift
//  WordleApp
//
//  Created by Doğa Erdemir on 15.10.2025.
//

struct GameSettings {
    var wordLength: Int = 5
    var guessLimit: Int = 5
    var hasTimeLimit: Bool = false
    var timeLimit: Int = 3
    var disableEliminatedLetters: Bool = false
}