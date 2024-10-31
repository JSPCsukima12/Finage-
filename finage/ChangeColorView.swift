import SwiftUI

struct ChangeColorView: View {
    @ObservedObject var share: ShareContent
    @State private var colorListDefault: [(String, Color)] = [
        ("デフォルト", .green.opacity(0.4))
    ]
    @State private var colorListSeasons: [(String, Color)] = [
        ("春", .pink.opacity(0.5)),
        ("夏", .green.opacity(0.7)),
        ("秋", .caramel.opacity(0.8)),
        ("冬", Color(red: 0.4, green: 0.6, blue: 0.8))
    ]
    
    var body: some View {
        NavigationStack {
            List {
                // デフォルトカラーセクション
                Section(header: Text("デフォルト")) {
                    ForEach(colorListDefault, id: \.0) { colorPair in
                        colorSelectionRow(colorPair: colorPair)
                    }
                }
                
                // 季節カラーセクション
                Section(header: Text("季節")) {
                    ForEach(colorListSeasons, id: \.0) { colorPair in
                        colorSelectionRow(colorPair: colorPair)
                    }
                }
            }
            .navigationTitle("アプリのカラー変更")
            .toolbarBackground(share.themeColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                // デバッグ用に現在のテーマカラーを出力
                print("Current themeColor: \(share.themeColor)")
            }
        }
    }
    
    // カラー選択のボタン表示を共通化
    @ViewBuilder
    private func colorSelectionRow(colorPair: (String, Color)) -> some View {
        let key = colorPair.0
        let color = colorPair.1
        
        Button(action: {
            share.themeColor = color // themeColorを更新
        }) {
            HStack {
                if isSimilarColor(color1: share.themeColor, color2: color) {
                    // 色が似ている場合、チェックマークを表示
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
                Rectangle()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(color)
                    .border(.black)
                Text(key)
                    .foregroundColor(.primary)
                Spacer()
            }
        }
    }
    
    // 色の類似性を判定する関数
    private func isSimilarColor(color1: Color, color2: Color, tolerance: CGFloat = 0.1) -> Bool {
        let components1 = UIColor(color1).cgColor.components ?? []
        let components2 = UIColor(color2).cgColor.components ?? []
        
        guard components1.count >= 4 && components2.count >= 4 else { return false }
        
        let redDiff = abs(components1[0] - components2[0])
        let greenDiff = abs(components1[1] - components2[1])
        let blueDiff = abs(components1[2] - components2[2])
        let alphaDiff = abs(components1[3] - components2[3]) // 透明度の差を計算
        
        return redDiff < tolerance && greenDiff < tolerance && blueDiff < tolerance && alphaDiff < tolerance
    }
}

// カスタムカラーの定義
extension Color {
    static let caramel = Color(red: 0.99, green: 0.74, blue: 0.5) // 明るめのキャラメル色
}
