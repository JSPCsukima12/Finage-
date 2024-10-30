import SwiftUI
import AuthenticationServices

struct InitialSetupView: View {
    @ObservedObject var share: ShareContent
    let onComplete: () -> Void // 完了時に呼び出されるクロージャ

    var body: some View {
        NavigationStack {
            Form {
                Section(header: HStack {
                    Text("テーマカラーの選択")
                }) {
                    NavigationLink(destination: ChangeColorView(share: share)) {
                        HStack {
                            Image(systemName: "app.fill")
                                .foregroundStyle(share.themeColor)
                            Text("テーマカラー")
                        }
                    }
                }
                
                Section(header: HStack {
                    Text("支払い方法/収入形態の登録")
                }) {
                    NavigationLink(destination: AddMethod(share: share, text: "支払い方法")) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                            Text("支払い方法の追加")
                        }
                    }
                    NavigationLink(destination: AddMethod(share: share, text: "収入形態")) {
                        HStack {
                            Image(systemName: "banknote")
                            Text("収入形態の追加")
                        }
                    }
                }

                Button("設定完了") {
                    onComplete() // 完了時にクロージャを呼び出す
                }
            }
            .navigationBarTitle("初期設定", displayMode: .inline)
            .toolbarBackground(share.themeColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            
            // フォームの外にメッセージを配置
            Text("設定は後から修正できます。")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .center) // センターに配置
        }
    }
}
