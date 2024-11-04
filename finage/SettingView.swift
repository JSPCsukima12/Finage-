import SwiftUI
import StoreKit
import UIKit
import UserNotifications

struct SettingView: View {
    @ObservedObject var share: ShareContent
    
    @State private var showAlert = false // アラート表示のトリガー
    @State private var notificationsEnabled = false // 通知の許可状況
    @State private var notificationTime = Date() // 通知の時間

    var body: some View {
        NavigationStack {
            Form {
                Section(header: HStack {
                    Text("テーマカラー変更")
                }) {
                    NavigationLink(destination: ChangeColorView(share: share)) {
                        HStack {
                            Image(systemName: "app.fill")
                                .foregroundStyle(share.themeColor)
                            Text("アプリのカラー変更")
                        }
                    }
                }
                
                Section(header: HStack {
                    Text("固定費関連")
                }) {
                    NavigationLink(destination: RegistSubscriptionView(share: share)) {
                        HStack {
                            Image(systemName: "music.note.list")
                            Text("サブスクの登録/編集")
                        }
                    }
                }
                
                Section(header: HStack {
                    Text("データ関連の消去")
                }) {
                    Button(action: {
                        showAlert = true
                    }) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text("全ての収支記録を消去する")
                        }
                        .foregroundStyle(.red)
                    }
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("最終確認"),
                            message: Text("本当に全ての収支記録を消去してもよろしいですか？\nこの操作は元に戻せません。"),
                            primaryButton: .destructive(Text("消去する")) {
                                share.deleteAllRecords()
                            },
                            secondaryButton: .cancel(Text("キャンセル"))
                        )
                    }
                }
                
                Section(header: HStack {
                    Text("評価/共有/お問い合わせ")
                }) {
                    Button(action: {
                        requestAppReview()
                    }) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("アプリを評価する")
                        }
                    }
                    .foregroundStyle(.blue)
                    
                    Button(action: {
                        shareApp()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("アプリを共有する")
                        }
                    }
                    .foregroundStyle(.blue)
                    
                    Button(action: {
                        sendEmail()
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("「Finage+」に関するお問い合わせ")
                        }
                    }
                    .foregroundStyle(.blue)
                }
                
                Section(header: HStack {
                    Text("その他")
                }) {
                    NavigationLink(destination: PrivacyPolicyView(share: share)) {
                        HStack {
                            Image(systemName: "hand.raised")
                            Text("プライバシーポリシー")
                        }
                    }
                    
                    HStack {
                        Image(systemName: "applescript.fill")
                        Text("バージョン:")
                        Spacer()
                        Text("1.3")
                    }
                }
            }
            .navigationBarTitle("設定", displayMode: .inline)
            .toolbarBackground(share.themeColor, for: .navigationBar) 
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                checkNotificationAuthorization()
            }
        }
        .tint(.blue)
    }
    
    // 通知の許可状況を確認するメソッド
    func checkNotificationAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = (settings.authorizationStatus == .authorized)
            }
        }
    }
    
    // App Storeでアプリを評価するためのメソッド
    func requestAppReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    // アプリを共有するためのメソッド
    func shareApp() {
        let appID = "6737231191"
        let appURL = "https://apps.apple.com/app/id\(appID)"
        let activityVC = UIActivityViewController(activityItems: [appURL], applicationActivities: nil)
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        if let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true, completion: nil)
        }
    }
    
    // メールアプリを開くメソッド
    func sendEmail() {
        let email = "squidramune@gmail.com"
        let subject = "「Finage+」に関するお問い合わせ"
        let body = ""
        
        if let url = URL(string: "mailto:\(email)?subject=\(subject)&body=\(body)") {
            UIApplication.shared.open(url)
        }
    }
}

struct CustomToggleStyle: ToggleStyle {
    var onColor: Color
    var offColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Button(action: {
                configuration.isOn.toggle()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(configuration.isOn ? onColor : offColor)
                        .frame(width: 60, height: 30)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 14 : -14)
                }
                .animation(.easeInOut, value: configuration.isOn)
            }
        }
    }
}

