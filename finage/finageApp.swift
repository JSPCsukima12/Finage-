import SwiftUI
import RealmSwift
import GoogleMobileAds
import UserNotifications
import UserMessagingPlatform
import AppTrackingTransparency

@main
struct finageApp: SwiftUI.App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var shareContent = ShareContent()
    @State private var isFirstLaunch: Bool = true
    @State private var isInitialSetupComplete: Bool = false

    init() {
        if UserDefaults.standard.object(forKey: "isFirstLaunch") == nil {
            UserDefaults.standard.set(true, forKey: "isFirstLaunch")
        }
    }

    var body: some Scene {
        WindowGroup {
            let firstLaunch = UserDefaults.standard.bool(forKey: "isFirstLaunch")
            
            if firstLaunch && !isInitialSetupComplete {
                InitialSetupView(share: shareContent, onComplete: {
                    withAnimation {
                        isInitialSetupComplete = true
                        UserDefaults.standard.set(false, forKey: "isFirstLaunch")
                        requestNotificationPermission()
                        requestTrackingPermission()
                        scheduleDailyNotification() // 通知のスケジュール
                    }
                })
                .transition(.opacity)
            } else {
                ContentView()
                    .environmentObject(shareContent)
                    .transition(.opacity)
            }
        }
    }
    
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    func requestTrackingPermission() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    print("User granted tracking permission.")
                case .denied:
                    print("User denied tracking permission.")
                case .notDetermined:
                    print("User has not determined tracking permission.")
                case .restricted:
                    print("User tracking permission is restricted.")
                @unknown default:
                    print("Unknown status.")
                }
            }
        }
    }
    
    func scheduleDailyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "お知らせ"
        content.body = "毎日の通知です！"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 18
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "DailyNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily notification: \(error)")
            } else {
                print("Daily notification scheduled for 18:00.")
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    var shareContent = ShareContent() // ShareContentのインスタンスをここで作成

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Realmの初期化
        let config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                // 必要に応じてマイグレーション処理を追加
            },
            objectTypes: [PaymentRecord.self, SubscriptionData.self] // 追加
        )
        Realm.Configuration.defaultConfiguration = config

        do {
            let realm = try Realm() // Realmを初期化
            print("Realm initialized successfully at: \(realm.configuration.fileURL?.absoluteString ?? "unknown path")")
        } catch {
            print("Error initializing Realm: \(error.localizedDescription)")
        }

        // Google Mobile Adsの初期化
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        // サブスクリプションの支払いを記録
        checkAndRecordSubscriptionPayments()

        // 毎日18:00に通知をスケジュール
        scheduleDailyNotification()
        return true
    }

    func checkAndRecordSubscriptionPayments() {
        shareContent.recordSubscriptionPayments() // 直接インスタンスを使用
    }

    // 毎日18:00に通知をスケジュールする関数
    func scheduleDailyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Finage+"
        content.body = "今日の支出記録は済んでいますか?"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 18
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "DailyNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily notification: \(error)")
            } else {
                print("Daily notification scheduled for 18:00.")
            }
        }
    }
}
