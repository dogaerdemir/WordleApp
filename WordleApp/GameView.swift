//
//  ContentView.swift
//  WordleApp
//
//  Created by Doğa Erdemir on 15.10.2025.
//

import SwiftUI
import Combine

// MARK: - Model

enum LetterResult {
    case none, correct, misplaced, wrong
}

struct LetterBox {
    var character: String = ""
    var result: LetterResult = .none
}

struct GameSettings {
    var wordLength: Int = 5
    var guessLimit: Int = 5
    var hasTimeLimit: Bool = false
    var timeLimit: Int = 3
    var disableEliminatedLetters: Bool = false
}

// MARK: - Repository (kelime önbelleği)

@MainActor
final class WordRepository: ObservableObject {
    static let shared = WordRepository()
    @Published private(set) var words: [String] = []
    private init() {}
    
    func loadWordsIfNeeded() async {
        if !words.isEmpty { return }
        guard let url = URL(string: "https://raw.githubusercontent.com/mertemin/turkish-word-list/master/words.txt") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let text = String(data: data, encoding: .utf8) {
                let all = text.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                    .filter {
                        !$0.isEmpty &&
                        !$0.contains(" ") &&
                        !$0.contains("-") &&
                        $0.allSatisfy({ $0.isLetter })
                    }
                self.words = all
            }
        } catch {
            print("Kelime listesi alınamadı: \(error)")
        }
    }
}

// MARK: - ViewModel

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

// MARK: - GameView

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WordleViewModel
    
    private let keyRows: [[String]] = [
        ["E","R","T","Y","U","I","O","P","Ğ","Ü"],
        ["A","S","D","F","G","H","J","K","L","Ş","İ"],
        ["Z","X","C","V","B","N","M","Ö","Ç"]
    ]
    
    init(settings: GameSettings, words: [String]) {
        _viewModel = StateObject(wrappedValue: WordleViewModel(settings: settings, words: words))
    }
    
    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            VStack(spacing: 10) {
                if let _ = viewModel.timeRemaining, !viewModel.gameOver {
                    Text("Süre:  \(viewModel.formattedTime())")
                        .font(.headline)
                } else {
                    Text("Süre:  -")
                        .font(.headline)
                }
                
                Spacer()
                
                ForEach(0..<viewModel.board.count, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(0..<viewModel.board[row].count, id: \.self) { col in
                            let box = viewModel.board[row][col]
                            Text(box.character)
                                .font(.system(size: 24, weight: .bold))
                                .frame(width: 45, height: 45)
                                .background(color(for: box.result))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray))
                        }
                    }
                }
                
                Spacer()
                
                GeometryReader { geo in
                    VStack(spacing: 8) {
                        ForEach(keyRows, id: \.self) { row in
                            HStack(spacing: 6) {
                                ForEach(row, id: \.self) { key in
                                    keyButton(key, width: keyWidth(for: row, geo: geo))
                                }
                            }
                        }
                        HStack(spacing: 10) {
                            Button {
                                viewModel.removeLetter()
                            } label: {
                                Image(systemName: "delete.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .frame(width: 60, height: 50)
                                    .background(Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            Button {
                                viewModel.submitGuess()
                            } label: {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 18, weight: .bold))
                                    .frame(width: 60, height: 50)
                                    .background(Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .frame(width: geo.size.width)
                }
                .frame(height: 250)
            }
            .padding()
            .alert("Süre Doldu", isPresented: $viewModel.showTimeUpAlert) {
                Button("Tamam") { dismiss() }
            } message: {
                Text("Süre sona erdi. Oyun bitti.")
            }
            .alert("Geçersiz Kelime", isPresented: $viewModel.invalidWordAlert) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text("Bu kelime listede bulunmuyor.")
            }
        }
        .navigationTitle("Wordle")
    }
    
    private func keyButton(_ letter: String, width: CGFloat) -> some View {
        let isDisabled = viewModel.eliminatedLetters.contains(letter.uppercased())
        
        return Button {
            viewModel.addLetter(letter)
        } label: {
            Text(letter)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: width, height: 50)
                .background(isDisabled ? Color.gray.opacity(0.3) : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .disabled(isDisabled)
    }
    
    private func keyWidth(for row: [String], geo: GeometryProxy) -> CGFloat {
        let spacing: CGFloat = 6
        let totalSpacing = spacing * CGFloat(row.count - 1)
        return (geo.size.width - totalSpacing - 16) / CGFloat(row.count)
    }
    
    private func color(for result: LetterResult) -> Color {
        switch result {
            case .correct: return .green
            case .misplaced: return .yellow
            case .wrong: return .gray
            case .none: return .clear
        }
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    @State private var settings = GameSettings()
    @State private var startGame = false
    @StateObject private var repo = WordRepository.shared
    
    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Ayarlar")
                    .font(.system(size: 26, weight: .bold))
                    .padding(.top, 45)
                
                HStack {
                    Text("Harf Sayısı").font(.system(size: 15))
                    Spacer()
                    Picker("", selection: $settings.wordLength) {
                        Text("4").tag(4)
                        Text("5").tag(5)
                        Text("6").tag(6)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
                .padding(.horizontal, 24)
                .padding(.top, 36)
                
                HStack {
                    Text("Tahmin Sayısı").font(.system(size: 15))
                    Spacer()
                    Picker("", selection: $settings.guessLimit) {
                        Text("4").tag(4)
                        Text("5").tag(5)
                        Text("6").tag(6)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                HStack {
                    Text("Elenen Harfleri Kapat").font(.system(size: 15))
                    Spacer()
                    Toggle("", isOn: $settings.disableEliminatedLetters)
                        .labelsHidden()
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                HStack {
                    Text("Süre Sınırı Aktif").font(.system(size: 15))
                    Spacer()
                    Toggle("", isOn: $settings.hasTimeLimit)
                        .labelsHidden()
                        .onChange(of: settings.hasTimeLimit) { newValue in
                            if newValue && settings.timeLimit == 0 {
                                settings.timeLimit = 3
                            }
                        }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                if settings.hasTimeLimit {
                    HStack {
                        Text("Süre (dk)").font(.system(size: 15))
                        Spacer()
                        Picker("", selection: $settings.timeLimit) {
                            ForEach(1...5, id: \.self) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                }
                
                Spacer()
                
                if repo.words.isEmpty {
                    ProgressView("Kelime listesi yükleniyor...")
                        .padding(.bottom, 30)
                } else {
                    Button(action: { startGame = true }) {
                        Text("Başla")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 54)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    
                    NavigationLink("", destination: GameView(settings: settings, words: repo.words), isActive: $startGame)
                        .hidden()
                }
            }
        }
        .task {
            await repo.loadWordsIfNeeded()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - App Entry

@main
struct WordleApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SettingsView()
            }
        }
    }
}

#Preview {
    //GameView(settings: GameSettings(), words: [""])
    SettingsView()
}
