//
//  LetterCellView.swift
//  WordleApp
//
//  Created by Doğa Erdemir on 19.10.2025.
//

import SwiftUI

struct LetterCellView: View {
    let box: LetterBox
    let row: Int
    let col: Int
    let color: Color
    
    @State private var scale: CGFloat = 1.0
    @State private var pulseToken: Int = 0
    
    var body: some View {
        Text(box.character)
            .font(.system(size: 24, weight: .bold))
            .frame(width: 54, height: 54)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray)
            )
            .scaleEffect(scale)
            .onChange(of: box.character) { _, newValue in
                guard !newValue.isEmpty else { return }
                runPulse()
            }
            .accessibilityIdentifier("cell_\(row)_\(col)")
    }
    
    private func runPulse() {
        pulseToken += 1
        let current = pulseToken
        
        scale = 1.0
        withAnimation(.interpolatingSpring(stiffness: 500, damping: 16)) {
            scale = 1.15
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            guard current == pulseToken else { return }
            withAnimation(.easeOut(duration: 0.12)) {
                scale = 1.0
            }
        }
    }
}
