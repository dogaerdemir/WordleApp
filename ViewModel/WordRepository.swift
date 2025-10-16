//
//  WordRepository.swift
//  WordleApp
//
//  Created by Doğa Erdemir on 15.10.2025.
//

import Foundation
import Combine

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