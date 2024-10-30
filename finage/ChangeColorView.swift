import SwiftUI

struct ChangeColorView: View {
    @ObservedObject var share: ShareContent
    @State private var colorList: [(String, Color)] = [
        ("デフォルト", .green.opacity(0.4)),
        ("春", .pink.opacity(0.5)),
        ("夏", .green.opacity(0.7)),
        ("秋", .caramel.opacity(0.8)),
        ("冬", Color(red: 0.4, green: 0.6, blue: 0.8))
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(colorList, id: \.0) { colorPair in
                    let key = colorPair.0
                    let color = colorPair.1
                    
                    Button(action: {
                        share.themeColor = color // themeColorを更新
                    }) {
                        HStack {
                            if share.themeColor == color {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue) // チェックマークの色
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
            }
            .navigationTitle("アプリのカラー変更")
            .toolbarBackground(share.themeColor, for: .navigationBar)  // NavigationBar の背景色を share.themeColor に設定
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// カスタムカラーの定義
extension Color {
    static let caramel = Color(red: 0.99, green: 0.74, blue: 0.5) // 明るめのキャラメル色
}
