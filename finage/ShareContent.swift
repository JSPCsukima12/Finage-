import SwiftUI
import Foundation
import RealmSwift

class PaymentRecord: Object {
    @Persisted(primaryKey: true) var id: ObjectId  // 一意のID
    @Persisted var date: Date = Date()             // 日付
    @Persisted var type: String = ""               // タイプ（出金 or 入金）
    @Persisted var method: String = ""             // 支払い手段
    @Persisted var amount: Int = 0                 // 金額
    @Persisted var memo: String = ""               // メモ
    @Persisted var points: Int = 0                 // 獲得ポイントを保存するプロパティ
}

class SubscriptionData: Object {
    @Persisted(primaryKey: true) var id: ObjectId  // 一意のID
    @Persisted var name: String = ""               // サブスクネーム
    @Persisted var genre: String = ""              // サブスクジャンル
    @Persisted var price: Int = 0                  // 料金
    @Persisted var plan: String = ""               // 体系（プランの種類）
    @Persisted var startDate: Date = Date()        // 開始日時
    @Persisted var paymentMethod: String = ""      // サブスクの支払い方法
    @Persisted var isActive: Bool = true           // サブスクが有効かどうか
}



// 支払い方法の詳細を持つ構造体
struct PaymentMethodDetail {
    var method: String           // 支払い方法
    var details: String          // 支払い詳細
    var earnsPoints: Bool        // ポイント管理の有無
    var baseFee: Int             // ポイント数をInt型に変更
}

class ShareContent: ObservableObject {
    private let methodDescription: [String] = ["現金払い", "クレジットカード", "QR決済", "電子マネー", "その他"]
    
    @Published var paymentMethod: [String: PaymentMethodDetail] = [
        "現金": PaymentMethodDetail(method: "現金", details: "現金払い", earnsPoints: false, baseFee: 0) // 初期値をInt型に合わせて修正
    ] {
        didSet {
            savePaymentMethod()
        }
    }
    
    @Published var incomeMethod: [String] = ["給料"] {
        didSet {
            saveIncomeMethod()
        }
    }
    
    @Published var alertBool: Bool = false {
        didSet {
            saveAlertBool()  
        }
    }
    
    @Published var paymentRecords: [PaymentRecord] = []
    @Published var methodData: [RankingData] = []
    @Published var detailData: [RankingData] = []
    @Published var subscriptionData: [SubscriptionData] = []
    
    @Published var themeColor: Color = .green.opacity(0.4) {
        didSet {
            saveThemeColor()
        }
    }
    
    private let themeColorUserDefaultsKey = "themeColor"
    private var notificationToken: NotificationToken? // Realmの変更を監視するトークン
    
    private let paymentUserDefaultsKey = "paymentMethod"
    private let incomeUserDefaultsKey = "incomeMethod"
    
    private let alertBoolUserDefaultsKey = "alertBool"
    
    init() {
        loadPaymentMethod()
        loadIncomeMethod()
        loadRankingData()
        loadThemeColor()
        loadSubscriptions()
        loadAlertBool()
    }

    deinit {
        notificationToken?.invalidate() // オブジェクト解放時に監視を停止
    }
    
    
    private func saveAlertBool() {
        UserDefaults.standard.set(alertBool, forKey: alertBoolUserDefaultsKey)
    }
    
    // Load alertBool from UserDefaults
    private func loadAlertBool() {
        alertBool = UserDefaults.standard.bool(forKey: alertBoolUserDefaultsKey)  // Default is false
    }
    
    func saveThemeColor() {
        saveColor(color: themeColor, forKey: themeColorUserDefaultsKey)
    }
    
    func saveColor(color: Color, forKey key: String) {
        let uiColor = UIColor(color)
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false) {
            UserDefaults.standard.set(colorData, forKey: key)
        }
    }
    
    func loadThemeColor() {
        themeColor = loadColor(forKey: themeColorUserDefaultsKey) ?? .green.opacity(0.4)
    }
    
    func loadColor(forKey key: String) -> Color? {
        if let colorData = UserDefaults.standard.data(forKey: key) {
            if let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                return Color(uiColor)
            }
        }
        return nil
    }

    // UserDefaultsに保存するメソッド
    func savePaymentMethod() {
        let savedMethods = paymentMethod.mapValues { methodDetail in
            return [
                "method": methodDetail.method,
                "details": methodDetail.details,
                "earnsPoints": methodDetail.earnsPoints,
                "points": methodDetail.baseFee // baseFeeをInt型として保存
            ]
        }
        UserDefaults.standard.set(savedMethods, forKey: paymentUserDefaultsKey)
    }

    private func saveIncomeMethod() {
        UserDefaults.standard.set(incomeMethod, forKey: incomeUserDefaultsKey)
    }

    // UserDefaultsからデータを読み込むメソッド
    private func loadPaymentMethod() {
        if let savedMethods = UserDefaults.standard.dictionary(forKey: paymentUserDefaultsKey) as? [String: [String: Any]] {
            paymentMethod = savedMethods.compactMapValues { methodDict in
                guard let method = methodDict["method"] as? String,
                      let details = methodDict["details"] as? String,
                      let earnsPoints = methodDict["earnsPoints"] as? Bool,
                      let points = methodDict["points"] as? Int else { return nil } // pointsをInt型として読み込む
                return PaymentMethodDetail(method: method, details: details, earnsPoints: earnsPoints, baseFee: points)
            }
        }
    }

    private func loadIncomeMethod() {
        if let savedMethods = UserDefaults.standard.array(forKey: incomeUserDefaultsKey) as? [String] {
            incomeMethod = savedMethods
        }
    }

    // 支払い記録を保存するメソッド
    func saveRecord(date: Date, type: String, method: String, amount: Int, memo: String) {
        let realm = try! Realm()

        let newRecord = PaymentRecord()
        newRecord.date = date
        newRecord.type = type
        newRecord.method = method
        newRecord.amount = amount
        newRecord.memo = memo
        
        // ポイント計算
        if let methodDetail = paymentMethod[method], methodDetail.earnsPoints {
            newRecord.points = (amount / methodDetail.baseFee) // 獲得ポイントを計算
        } else {
            newRecord.points = 0 // ポイントがない場合は0
        }

        try! realm.write {
            realm.add(newRecord)
        }
    }
    
    // 全ての記録を取得するメソッド
    func getAllRecords() -> Results<PaymentRecord> {
        let realm = try! Realm()
        return realm.objects(PaymentRecord.self)
    }
    
    func deleteRecord(_ record: PaymentRecord) {
        let realm = try! Realm()
        
        try! realm.write {
            realm.delete(record)
        }
    }
    
    // 指定された支払い手段に基づいて記録を削除するメソッド
    func deleteRecordsByMethod(method: String) {
        let realm = try! Realm()
        
        // 指定された手段に基づく全ての記録を取得
        let recordsToDelete = realm.objects(PaymentRecord.self).filter("method == %@", method)

        // Realmのトランザクションで削除処理を行う
        try! realm.write {
            realm.delete(recordsToDelete)
        }
    }
    
    // 全ての記録を削除するメソッド
    func deleteAllRecords() {
        let realm = try! Realm()
        
        try! realm.write {
            realm.delete(realm.objects(PaymentRecord.self))
        }
    }
    
    // ランキングデータをリアルタイムで取得・更新する
    func loadRankingData() {
        let realm = try! Realm()
        let results = realm.objects(PaymentRecord.self)
        
        // リアルタイムで変更を監視
        notificationToken = results.observe { [weak self] _ in
            guard let self = self else { return }
            let methodData = self.generateRankingData(from: results, test: 0)
            let detailData = self.generateRankingData(from: results, test: 1)
            DispatchQueue.main.async {
                self.methodData = methodData
                self.detailData = detailData
            }
        }
    }
    
    func getTotalPointByMethod(method: String, date: Date) -> Int {
        // 全ての記録を取得
        let records = getAllRecords()
        
        // 指定された手段と日付に関連するポイントを合計
        let totalPoints = records.filter { record in
            record.method == method && Calendar.current.isDate(record.date, inSameDayAs: date)
        }
        .reduce(0) { $0 + $1.points }
        
        return totalPoints
    }
    
    func calculateIncomeAndExpense() -> (totalIncome: Int, totalExpense: Int) {
        let realm = try! Realm()

        // 全ての支払い記録を取得
        let allRecords = realm.objects(PaymentRecord.self)

        // 収入と支出をそれぞれ集計
        let totalIncome = allRecords.filter("type == '入金'").reduce(0) { $0 + $1.amount }
        let totalExpense = allRecords.filter("type == '出金'").reduce(0) { $0 + $1.amount }

        return (totalIncome, totalExpense)
    }

    
    func getRecordsByMethod(genre: String, method: String, on date: Date) -> [PaymentRecord] {
        let records = getAllRecords()
        
        // 指定された支払い手段と日付に基づいてフィルタリング
        let filteredRecords = records.filter {
            $0.method == method &&
            $0.type == genre &&
            Calendar.current.isDate($0.date, inSameDayAs: date) // 日付を比較
        }
        
        return Array(filteredRecords)
    }
    
    private func generateRankingData(from records: Results<PaymentRecord>, test: Int) -> [RankingData] {
        var rankingData: [RankingData] = []

        // 出金記録のみをフィルタリング
        let expenseRecords = records.filter { $0.type == "出金" }
        
        // 集計のためのグループ化
        let groupedMethods: [String: [PaymentRecord]]
        
        if test == 0 {
            // testが0の場合は、$0.methodを使用
            groupedMethods = Dictionary(grouping: expenseRecords) { $0.method }
        } else {
            // testが1の場合は、paymentMethod辞書の値を使用
            groupedMethods = Dictionary(grouping: expenseRecords) { paymentMethod[$0.method]?.details ?? "未定義" }
        }

        for (method, payments) in groupedMethods {
            let totalAmount = payments.reduce(0) { $0 + $1.amount }

            // アイコン名の取得
            let imageName: String
            imageName = methodToImageName(paymentMethod[method]?.details ?? method) // paymentMethodの値を参照
            
            rankingData.append(RankingData(imageName: imageName, paymentName: method, fee: "\(totalAmount)"))
        }

        // 金額の降順に並び替え
        rankingData.sort { Int($0.fee) ?? 0 > Int($1.fee) ?? 0 }

        return rankingData
    }
    
    func aggregatePointsByMethod() -> [String: Int] {
        // 全ての記録を取得
        let records = getAllRecords()
        
        // 支払い方法ごとにポイントを集計する辞書を作成
        var pointsByMethod: [String: Int] = [:]

        // 全ての記録を処理してポイントを集計
        for record in records {
            // incomeMethodに含まれるもの、またはpaymentMethodでearnPointsがfalseの場合はスキップ
            if incomeMethod.contains(record.method) || (paymentMethod[record.method]?.earnsPoints == false) {
                continue
            }
            pointsByMethod[record.method, default: 0] += record.points
        }

        // 支払い方法を取得し、ポイントが0のものも追加
        for (method, detail) in paymentMethod {
            if detail.earnsPoints {
                pointsByMethod[method] = pointsByMethod[method] ?? 0 // earnPointsがtrueのものだけ追加
            }
        }
        
        return pointsByMethod
    }

    // 支払い手段に応じたアイコンを取得するメソッド
    func methodToImageName(_ method: String) -> String {
        switch method {
        case "現金払い":
            return "yensign"
        case "クレジットカード":
            return "creditcard"
        case "QR決済":
            return "qrcode"
        case "電子マネー":
            return "wave.3.left.circle.fill"
        case "その他":
            return "questionmark"
        default:
            return "banknote"
        }
    }
    
    func genreToIMmageName(_ genre: String) -> String {
        switch genre {
        case "音楽配信":
            return "music.note"
        case "動画配信":
            return "movieclapper"
        case "書籍":
            return "book"
        case "ファッション":
            return "tshirt"
        case "ゲーム":
            return "gamecontroller"
        default:
            return "ellipsis"
        }
    }
    
    func loadSubscriptions() {
        let realm = try! Realm()
        let results = realm.objects(SubscriptionData.self)
        subscriptionData = Array(results)
    }
        
    func recordSubscriptionData(name: String, genre: String, price: Int, plan: String, startDate: Date, paymentMethod: String, isActive: Bool) {
        let realm = try! Realm()
        let newSubscription = SubscriptionData()
        newSubscription.name = name
        newSubscription.genre = genre
        newSubscription.price = price
        newSubscription.plan = plan
        newSubscription.startDate = startDate
        newSubscription.paymentMethod = paymentMethod
        newSubscription.isActive = isActive  // 正しくBool値を設定

        try! realm.write {
            realm.add(newSubscription)
        }

        loadSubscriptions()
    }
    
    func recordSubscriptionPayments() {
        let currentDate = Date()
        let calendar = Calendar.current
        let realm = try! Realm()
        let subscriptions = realm.objects(SubscriptionData.self)

        for subscription in subscriptions {
            // サブスクリプションがアクティブであるか確認
            if subscription.isActive {
                // サブスクリプションの開始日時のdayを取得
                let subscriptionDay = calendar.component(.day, from: subscription.startDate)
                let currentDay = calendar.component(.day, from: currentDate)

                // 開始日のdayと現在の日が一致する場合に支払いを記録
                if subscriptionDay == currentDay {
                    // 同じ日にすでに支払いが記録されていないか確認
                    let startOfDay = calendar.startOfDay(for: currentDate)
                    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

                    let existingPayment = realm.objects(PaymentRecord.self)
                        .filter("memo == %@ AND date >= %@ AND date < %@", subscription.name, startOfDay, endOfDay)
                        .first

                    if existingPayment == nil {
                        // 新しい支払い記録を追加
                        let newPayment = PaymentRecord()
                        newPayment.date = currentDate
                        newPayment.type = "出金"
                        newPayment.method = subscription.paymentMethod
                        newPayment.amount = subscription.price
                        newPayment.memo = subscription.name

                        try! realm.write {
                            realm.add(newPayment)
                        }
                    }
                }
            }
        }
    }
}

struct CustomTextFieldWithToolbar: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var keyboardType: UIKeyboardType // キーボードタイプを追加
    var onCommit: () -> Void

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomTextFieldWithToolbar

        init(_ parent: CustomTextFieldWithToolbar) {
            self.parent = parent
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            self.parent.onCommit()
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = textField.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
            self.parent.text = updatedText
            return true
        }

        @objc func didTapCancel() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            parent.text = "" // テキストをリセット
        }

        @objc func didTapDone() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.borderStyle = .none // ボーダーを削除
        textField.keyboardType = keyboardType // キーボードタイプを設定
        textField.inputAccessoryView = createToolbar(context: context)
        textField.textAlignment = .right // テキストを右寄りに設定
        
        // デフォルトの高さを維持
        textField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        
        // 予測変換を有効にする
        textField.autocorrectionType = .yes
        textField.smartQuotesType = .default // スマートクォートを有効
        textField.smartInsertDeleteType = .default // スマートインサートと削除を有効

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    // キーボードの上にツールバーを作成
    private func createToolbar(context: Context) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let cancelButton = UIBarButtonItem(title: "キャンセル", style: .plain, target: context.coordinator, action: #selector(Coordinator.didTapCancel))
        let doneButton = UIBarButtonItem(title: "完了", style: .done, target: context.coordinator, action: #selector(Coordinator.didTapDone))
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.setItems([cancelButton, flexSpace, doneButton], animated: true)
        return toolbar
    }
}

struct RankingData: Hashable {
    var id = UUID()
    var imageName: String
    let paymentName: String
    var fee: String
}