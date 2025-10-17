//
//  WordleAppTests.swift
//  WordleAppTests
//
//  Created by Doğa Erdemir on 15.10.2025.
//

import XCTest
@testable import WordleApp

@MainActor
final class WordleAppTests: XCTestCase {
    
    func testLoadWords_Success_ParsesList() async throws {
        let text = "kalem\nbursa\nizmir\nçay-\n"
        let data = text.data(using: .utf8)!
        let url = URL(string: "https://example.com/words.txt")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
        
        URLProtocolStub.register(data: data, response: response, error: nil)
        let session = URLProtocolStub.makeSession()
        let repo = WordRepository(session: session, sourceURL: url)
        
        await repo.loadWordsIfNeeded()
        XCTAssertTrue(repo.words.contains("kalem"))
        XCTAssertTrue(repo.words.contains("bursa"))
        XCTAssertTrue(repo.words.contains("izmir"))
        XCTAssertFalse(repo.words.contains("çay-"))
    }
    
    func testLoadWords_Failure_KeepsEmpty() async throws {
        let url = URL(string: "https://example.com/words.txt")!
        URLProtocolStub.register(data: nil, response: nil, error: URLError(.notConnectedToInternet))
        let session = URLProtocolStub.makeSession()
        let repo = WordRepository(session: session, sourceURL: url)
        
        await repo.loadWordsIfNeeded()
        XCTAssertTrue(repo.words.isEmpty)
    }
    
    func testEvaluateGuess_AllCorrect() {
        let settings = GameSettings()
        let viewModel = WordleViewModel(settings: settings, words: ["kalem"], startTimerImmediately: false)
        viewModel.targetWord = "KALEM"
        
        let result = viewModel.evaluateGuess("KALEM")
        
        XCTAssertEqual(result, Array(repeating: LetterResult.correct, count: 5))
    }
    
    func testEvaluateGuess_AllWrong() {
        let settings = GameSettings()
        let viewModel = WordleViewModel(settings: settings, words: ["kalem"], startTimerImmediately: false)
        viewModel.targetWord = "KALEM"
        
        let result = viewModel.evaluateGuess("BURSA")
        
        XCTAssertEqual(result[0], .wrong)
        XCTAssertEqual(result[1], .wrong)
        XCTAssertEqual(result[2], .wrong)
        XCTAssertEqual(result[3], .wrong)
        XCTAssertEqual(result[4], .misplaced)
    }
    
    func testEvaluateGuess_MixedResults() {
        let settings = GameSettings()
        let viewModel = WordleViewModel(settings: settings, words: ["kalem"], startTimerImmediately: false)
        viewModel.targetWord = "KALEM"
        
        let result = viewModel.evaluateGuess("LAMER")
        
        XCTAssertEqual(result[0], .misplaced)
        XCTAssertEqual(result[1], .correct)
    }
    
    func testInvalidWordRejected() {
        let settings = GameSettings()
        let viewModel = WordleViewModel(settings: settings, words: ["kalem", "masa"], startTimerImmediately: false)
        
        viewModel.targetWord = "KALEM"
        viewModel.board[0] = [
            LetterBox(character: "X"),
            LetterBox(character: "Y"),
            LetterBox(character: "Z"),
            LetterBox(character: "Q"),
            LetterBox(character: "W")
        ]
        viewModel.currentCol = 5
        viewModel.submitGuess()
        
        XCTAssertTrue(viewModel.invalidWordAlert)
        XCTAssertFalse(viewModel.gameOver)
    }
    
    func testEliminatedLettersAdded() {
        var settings = GameSettings()
        settings.disableLetters = true
        
        let viewModel = WordleViewModel(settings: settings, words: ["kalem", "bursa"], startTimerImmediately: false)
        viewModel.targetWord = "KALEM"
        
        viewModel.board[0] = [
            LetterBox(character: "B"),
            LetterBox(character: "U"),
            LetterBox(character: "R"),
            LetterBox(character: "S"),
            LetterBox(character: "A")
        ]
        viewModel.currentCol = 5
        viewModel.submitGuess()
        
        XCTAssertTrue(viewModel.eliminatedLetters.contains("B"))
        XCTAssertTrue(viewModel.eliminatedLetters.contains("U"))
        XCTAssertTrue(viewModel.eliminatedLetters.contains("R"))
        XCTAssertTrue(viewModel.eliminatedLetters.contains("S"))
        XCTAssertFalse(viewModel.eliminatedLetters.contains("A"))
    }
    
    func testDictionaryLookupHandlesCapitalIDotted() async {
        var settings = GameSettings()
        settings.disableLetters = false
        let vm = WordleViewModel(settings: settings, words: ["terim"], startTimerImmediately: false)
        vm.targetWord = "KALem".uppercased()
        
        vm.board[0] = [
            LetterBox(character: "T"),
            LetterBox(character: "E"),
            LetterBox(character: "R"),
            LetterBox(character: "İ"),
            LetterBox(character: "M")
        ]
        vm.currentCol = 5
        
        vm.submitGuess()
        
        XCTAssertFalse(vm.invalidWordAlert)
    }
}
