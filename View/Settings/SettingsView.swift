//
//  SettingsView.swift
//  WordleApp
//
//  Created by Doğa Erdemir on 15.10.2025.
//

import SwiftUI

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
                    Text("Hatalı Harfleri Soluklaştır").font(.system(size: 15))
                    Spacer()
                    Toggle("", isOn: $settings.disableLetters)
                        .labelsHidden()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                HStack {
                    Text("Süre Sınırı Ayarla").font(.system(size: 15))
                    Spacer()
                    Toggle("", isOn: $settings.hasTimeLimit)
                        .labelsHidden()
                        .onChange(of: settings.hasTimeLimit) { _, newValue in
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
