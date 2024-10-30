import SwiftUI

struct ContentView: View {
    @ObservedObject private var share = ShareContent()
    @State private var isLaunching = true // ロード中の状態

    init() {
        setupNavigationBarAppearance(UIColor(share.themeColor))
        setupTabBarAppearance()
    }

    var body: some View {
        Group {
            if isLaunching {
                LaunchView() // LaunchViewを表示
                    .onAppear {
                        // 1.5秒後にアニメーションをつけてTabViewを表示
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                isLaunching = false
                            }
                        }
                    }
            } else {
                TabView {
                    RecordView(share: share)
                        .tabItem {
                            Image(systemName: "pencil")
                            Text("記録")
                        }
                    ReportView(share: share)
                        .tabItem {
                            Image(systemName: "list.bullet.clipboard")
                            Text("分析")
                        }
                    CalendarView(share: share)
                        .tabItem {
                            Image(systemName: "calendar")
                            Text("カレンダー")
                        }
                    SettingView(share: share)
                        .tabItem {
                            Image(systemName: "gear")
                            Text("設定")
                        }
                }
                .accentColor(share.themeColor)
                .onAppear {
                    setupNavigationBarAppearance(UIColor(share.themeColor))
                }
                .onChange(of: share.themeColor) { newColor in
                    setupNavigationBarAppearance(UIColor(newColor))
                }
            }
        }
        .transition(.opacity) // フェードイン・フェードアウトアニメーション
    }

    func setupNavigationBarAppearance(_ color: UIColor) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground() // 背景を透明に設定
        appearance.backgroundColor = color // 背景色を設定
        appearance.shadowColor = .clear // シャドウをクリアに設定して境界線をなくす
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black] // タイトルの色を設定

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance // コンパクト表示用にも設定
        UINavigationBar.appearance().isTranslucent = false // 透過を無効にする
    }

    func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground() // 不透明な背景を設定
        appearance.backgroundColor = UIColor.white // TabBarの背景色を白に固定

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
