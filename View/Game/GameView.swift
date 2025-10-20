//
//  ContentView.swift
//  WordleApp
//
//  Created by Doğa Erdemir on 15.10.2025.
//

import SwiftUI
import Combine

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WordleViewModel
    
    private let keyRows: [[String]] = [
        ["E","R","T","Y","U","I","O","P","Ğ","Ü"],
        ["A","S","D","F","G","H","J","K","L","Ş","İ"],
        ["<DEL>","Z","C","V","B","N","M","Ö","Ç","<SUB>"]
    ]
    
    init(settings: GameSettings, words: [String]) {
        _viewModel = StateObject(wrappedValue: WordleViewModel(settings: settings, words: words))
    }
    
    var body: some View {
        ZStack {
            Color(.bgMain).ignoresSafeArea()
            VStack(spacing: 10) {
                if let _ = viewModel.timeRemaining, !viewModel.gameOver {
                    Text("Süre:  \(viewModel.formattedTime())").font(.headline)
                } else {
                    Text("Süre:  -").font(.headline)
                }
                
                Spacer()
                
                ForEach(0..<viewModel.board.count, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(0..<viewModel.board[row].count, id: \.self) { col in
                            let box = viewModel.board[row][col]
                            LetterCellView(
                                box: box,
                                row: row,
                                col: col,
                                color: color(for: box.result)
                            )
                        }
                    }
                }
                
                Spacer()
                
                GeometryReader { geo in
                    VStack {
                        VStack(spacing: 8) {
                            ForEach(keyRows, id: \.self) { row in
                                HStack(spacing: 6) {
                                    ForEach(row, id: \.self) { key in
                                        let w = keyWidth(for: row, geo: geo)
                                        if key == "<DEL>" {
                                            systemKeyButton("delete.left", width: w) {
                                                viewModel.removeLetter()
                                            }
                                        } else if key == "<SUB>" {
                                            systemKeyButton("checkmark", width: w) {
                                                viewModel.submitGuess()
                                            }
                                        } else {
                                            keyButton(key, width: w)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .frame(height: 260)
            }
            .padding()
            .alert("Süre Doldu", isPresented: $viewModel.showTimeUpAlert) {
                Button("Bitir") { dismiss() }
            } message: {
                Text("Süre sona erdi. Oyun bitti.")
            }
            .alert("Geçersiz Kelime", isPresented: $viewModel.invalidWordAlert) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text("Bu kelime geçerli değil.")
            }
            .alert("Tebrikler", isPresented: Binding(
                get: { viewModel.gameResult == .won },
                set: { if !$0 { viewModel.gameResult = nil; dismiss() } }
            )) {
                Button("Bitir") { viewModel.gameResult = nil; dismiss() }
            } message: {
                Text("Tebrikler! Kelimeyi doğru bildiniz.")
            }
            .alert("Başarısız", isPresented: Binding(
                get: { viewModel.gameResult == .lost },
                set: { if !$0 { viewModel.gameResult = nil; dismiss() } }
            )) {
                Button("Bitir") { viewModel.gameResult = nil; dismiss() }
            } message: {
                Text("Doğru kelime: \(viewModel.targetWord.lowercased(with: Locale(identifier: "tr_TR")))")
            }
        }
        .navigationTitle("WORDLE")
    }
    
    private func keyButton(_ letter: String, width: CGFloat) -> some View {
        let upper = letter.uppercased()
        let highlightOn = viewModel.highlightEnabled
        let isCorrectKnown = highlightOn && viewModel.correctLetters.contains(upper)
        let isEliminated = highlightOn && viewModel.eliminatedLetters.contains(upper) && !isCorrectKnown
        let bg: Color = {
            if isCorrectKnown { return .bgCorrectGuess }
            if isEliminated { return .bgButtonGray.opacity(0.33) }
            return .bgButtonGray
        }()
        
        return Button {
            viewModel.addLetter(letter)
        } label: {
            Text(letter)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: width, height: 50)
                .background(bg)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
    
    private func systemKeyButton(_ systemName: String, width: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: width, height: 50)
                .background(Color.bgButtonGray)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
    
    private func keyWidth(for row: [String], geo: GeometryProxy) -> CGFloat {
        let spacing: CGFloat = 6
        let totalSpacing = spacing * CGFloat(row.count - 1)
        return (geo.size.width - totalSpacing - 16) / CGFloat(row.count)
    }
    
    private func color(for result: LetterResult) -> Color {
        switch result {
            case .correct: return .bgCorrectGuess
            case .misplaced: return .bgMisplacedGuess
            case .wrong: return .bgWrongGuess
            case .none: return .clear
        }
    }
}

#Preview {
    GameView(settings: GameSettings(), words: [])
}
