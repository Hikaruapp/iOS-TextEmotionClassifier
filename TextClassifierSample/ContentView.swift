// TextClassifierSampleApp.swift
// シンプルな SwiftUI テキスト分類サンプル

import SwiftUI
import NaturalLanguage
import CoreML
import UIKit

// 判定サンプル文章
//「最近、詐欺メールがたくさん届いて本当に怒りを感じる。友達と話しているときは楽しいけれど、詐欺に騙されそうになった話を聞くと悲しくなる。でも、今日は無事にスパムメールをブロックできたから、ちょっと嬉しかった！」

struct ContentView: View {
    @State private var inputText: String = ""
    @State private var predictions: [(label: String, probability: Double)] = []
    private let classifier: NLModel? = {
        guard let mlModel = try? TextClassificationModel02(configuration: MLModelConfiguration()).model,
              let nlModel = try? NLModel(mlModel: mlModel) else {
            return nil
        }
        return nlModel
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Text Classifier サンプル")
                .font(.headline)

            TextEditor(text: $inputText)
                .frame(maxHeight: .infinity)
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray))

            HStack(spacing: 12) {
                Button("ペースト") {
                    if let paste = UIPasteboard.general.string {
                        inputText = paste
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "#4B6423"))
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(UIPasteboard.general.string == nil)

                Button("分析") {
                    guard let model = classifier, !inputText.isEmpty else { return }
                    let hypos = model.predictedLabelHypotheses(for: inputText, maximumCount: .max)
                    predictions = sortHypotheses(hypos)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "#BEBE73"))
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(inputText.isEmpty)

                Button("クリア") {
                    inputText = ""
                    predictions = []
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "#785A0A"))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(predictions, id: \.label) { pred in
                        VStack {
                            // after
                            Image(systemName: iconMapping(for: pred.label))
                                .font(.system(size: 48))
                            Text(pred.label)
                                .font(.caption)
                            Text(String(format: "%.1f%%", ceil(pred.probability * 1000) / 10))
                                .font(.caption2)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 120)

            Spacer()
        }
        .padding()
    }

    private func iconMapping(for label: String) -> String {
        print(label)
        let key = label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch key {
        case "angry":
            return "exclamationmark.triangle.fill"
        case "sad":
            return "cloud.drizzle.fill"
        case "happy":
            return "face.smiling.fill"
        case "spam":
            return "envelope.fill"
        case "non-spam":
            return "envelope"
        case "fraud":
            return "exclamationmark.shield.fill"
        default:
            return "questionmark.circle"
        }
    }

    private func sortHypotheses(_ hypos: [String: Double]) -> [(label: String, probability: Double)] {
        hypos.sorted { $0.value > $1.value }
             .map { (label: $0.key, probability: $0.value) }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
