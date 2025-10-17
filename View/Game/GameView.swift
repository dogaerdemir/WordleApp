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
        let isEliminated = viewModel.eliminatedLetters.contains(letter.uppercased())
        
        return Button {
            viewModel.addLetter(letter)
        } label: {
            Text(letter)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: width, height: 50)
                .background(isEliminated ? Color.gray.opacity(0.25) : Color.gray)
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
            case .correct: return .green
            case .misplaced: return .yellow
            case .wrong: return .gray
            case .none: return .clear
        }
    }
}
