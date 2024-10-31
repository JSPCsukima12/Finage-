import SwiftUI
import RealmSwift

struct RegistSubscriptionView: View {
    @ObservedObject var share: ShareContent
    @State private var selectedSubscriptions: Set<Int> = [] // 選択されたサブスクリプションのインデックスを管理
    @State private var isEditing = false // 編集モードの状態を管理
    @State private var isShowingAddSubscriptionView = false // 追加するビューを表示するフラグ

    var body: some View {
        VStack(spacing: 0) {
            if share.subscriptionData.isEmpty {
                Text("サブスクリプションが登録されていません")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                if isEditing {
                    Text("\(selectedSubscriptions.count) 件選択中")
                        .bold()
                        .padding(.top, 5.0)
                } else {
                    HStack {
                        HStack(spacing: 3) {
                            Circle()
                                .foregroundStyle(.blue)
                                .frame(width: 10, height: 10)
                            Text("更新継続")
                                .bold()
                        }
                        HStack(spacing: 3) {
                            Circle()
                                .foregroundStyle(.red)
                                .frame(width: 10, height: 10)
                            Text("更新停止")
                                .bold()
                        }
                    }
                    .padding(.top, 5.0)
                }
                List {
                    ForEach(share.subscriptionData.indices, id: \.self) { index in
                        SubscriptionView(share: share, subscription: share.subscriptionData[index], index: index, isSelected: selectedSubscriptions.contains(index), isEditing: isEditing, toggleSelection: {
                            toggleSelection(for: index) // チェックボックスのトグルアクション
                        })
                    }
                    if isEditing {
                        Button(action: {
                            deleteSelectedSubscriptions()
                            share.loadSubscriptions()
                        }) {
                            HStack {
                                Image(systemName:"trash.fill")
                                Text("削除する")
                            }
                        }
                        .foregroundStyle(selectedSubscriptions.count == 0 ? .gray : .red)
                        .disabled(selectedSubscriptions.count == 0)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationBarTitle("サブスク管理", displayMode: .inline)
        .toolbar {
            Button(action: {
                isEditing.toggle() // ゴミ箱ボタンを押した時に編集モードをトグル
            }) {
                Image(systemName: isEditing ? "checkmark.circle.fill" : "trash.fill")
                    .foregroundColor(isEditing ? .blue : .red)
            }
            Button(action: {
                isShowingAddSubscriptionView = true // 追加ビューを表示
            }) {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $isShowingAddSubscriptionView) {
            AddSubscriptionView(share: share) // 追加するビューを表示
        }
    }
    
    private func deleteSelectedSubscriptions() {
        let realm = try! Realm()
        // トランザクションを開始
        do {
            try realm.write {
                // 削除対象のオブジェクトを取得して削除
                for index in selectedSubscriptions.sorted(by: >) { // 後ろから削除
                    if let subscriptionToDelete = realm.object(ofType: SubscriptionData.self, forPrimaryKey: share.subscriptionData[index].id) {
                        realm.delete(subscriptionToDelete)
                    }
                }
                // 削除後、選択状態をリセット
                selectedSubscriptions.removeAll()
            }
        } catch {
            print("Error deleting subscription: \(error)")
        }
    }

    private func toggleSelection(for index: Int) {
        if selectedSubscriptions.contains(index) {
            selectedSubscriptions.remove(index) // すでに選択されている場合は選択を解除
        } else {
            selectedSubscriptions.insert(index) // 選択されていない場合は選択する
        }
    }
}


struct SubscriptionView: View {
    @ObservedObject var share: ShareContent
    var subscription: SubscriptionData
    var index: Int
    var isSelected: Bool
    var isEditing: Bool
    var toggleSelection: () -> Void

    var body: some View {
        Button(action: {
            if isEditing {
                toggleSelection() // 編集モードのときは選択をトグル
            } else {
                toggleSubscription(subscription)
                share.loadSubscriptions()
            }
        }) {
            HStack {
                if isEditing {
                    Image(systemName: isSelected ? "checkmark.square" : "square")
                        .foregroundColor(isSelected ? .blue : .gray)
                } else {
                    Circle()
                        .foregroundStyle(subscription.isActive ? .blue : .red)
                        .frame(width: 10, height: 10)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text(subscription.name)
                            .font(.headline)
                            .bold()
                        Spacer()
                        Image(systemName: share.genreToIMmageName(subscription.genre))
                    }
                    HStack {
                        Text("次回更新日: \(formattedDate(subscription.startDate))")
                        Spacer()
                        HStack(spacing: 0) {
                            let type: String = subscription.plan == "月額制" ? "月額" : "年額"
                            Text("(\(type))")
                            Text("\(subscription.price)円")
                        }
                    }
                }
                Spacer()
            }
        }
    }

    private func toggleSubscription(_ subscription: SubscriptionData) {
        // Realmインスタンスを取得
        let realm = try! Realm()
        
        // 変更を行うためのトランザクション
        do {
            try realm.write {
                // 指定したサブスクリプションのisActiveをトグル
                if let subscriptionToUpdate = realm.object(ofType: SubscriptionData.self, forPrimaryKey: subscription.id) {
                    subscriptionToUpdate.isActive.toggle()
                } else {
                    print("Error: Subscription not found in Realm")
                }
            }
        } catch {
            print("Error updating subscription: \(error)")
        }
    }

    // 日付をYYYY/MM/dd形式にフォーマットする関数
    private func formattedDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd" // YYYY/MM/dd形式を指定
        return dateFormatter.string(from: date) // フォーマットされた日付を返す
    }
}

struct AddSubscriptionView: View {
    @ObservedObject var share: ShareContent
    
    @State private var title: String = ""
    @State private var plan: [String] = ["月額制", "年額制"]
    @State private var planSelection: Int = 0
    @State private var genre: [String] = ["音楽配信","動画配信","ゲーム","書籍","ファッション","その他"]
    @State private var genreSelection: Int = 0
    @State private var selectKey: String = ""
    @State private var methodDescription: [String] = ["現金払い", "クレジットカード", "QR決済", "電子マネー", "その他"]
    @State private var fee: String = ""
    @State private var startDate: Date = Date()
    
    @State private var showAlert: Bool = false  // アラート表示フラグ
    @State private var alertMessage: String = "" // アラートメッセージ
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("サブスク名")
                        Spacer()
                        TextField("サブスク名を入力",text:$title)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("ジャンル", selection: $genreSelection) {
                        ForEach(0..<genre.count, id: \.self) { index in
                            HStack {
                                Image(systemName: share.genreToIMmageName(genre[index]))
                                Text(genre[index])
                                    .tag(index)
                            }
                        }
                    }
                    Picker("", selection: $planSelection) {
                        ForEach(0..<plan.count, id: \.self) { index in
                            Text(plan[index])
                                .tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    DatePicker("開始日時", selection: $startDate, displayedComponents: .date)
                    
                    Picker("支払い方法を選択", selection: $selectKey) {
                        Text("--選択してください--")
                        ForEach(sortedPaymentMethods(), id: \.key) { key, value in
                            HStack(spacing: 3) {
                                Image(systemName: share.methodToImageName(value.details))
                                Text(key)
                            }
                        }
                    }
                    HStack {
                        Text("料金")
                        Spacer()
                        CustomTextFieldWithToolbar(text: $fee, placeholder: "料金を入力", keyboardType: .numberPad, onCommit: {
                            
                        })
                        .frame(height:15)
                        Text("円")
                    }
                }
                Button("追加する") {
                    addSubscription() // 追加ボタンを押した時の処理
                }
            }
            .navigationBarTitle("サブスクの追加", displayMode: .inline)
            .navigationBarItems(leading: Button("閉じる") {
                dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(title: Text("エラー"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func addSubscription() {
        // サブスク名が空の場合はアラートを表示
        if title.isEmpty {
            alertMessage = "サブスク名を入力してください。"
            showAlert = true
            return
        }
        
        // 支払い方法が未選択の場合はアラートを表示
        if selectKey.isEmpty {
            alertMessage = "支払い方法を選択してください。"
            showAlert = true
            return
        }
        
        // 料金が空または0円の場合はアラートを表示
        if fee.isEmpty {
            alertMessage = "金額を入力してください。"
            showAlert = true
            return
        } else if Int(fee) == 0 {
            alertMessage = "金額は1円以上にしてください。"
            showAlert = true
            return
        }
        
        // 現在の日付を取得
        let currentDate = Date()
        
        // next の値を分岐させる
        let next: Date
        if Calendar.current.isDate(currentDate, inSameDayAs: startDate) {
            next = currentDate // startDateが今日の場合、そのままcurrentDateを使用
        } else {
            next = share.calculateNextPaymentDate(plan: plan[planSelection], startDate: startDate) // 今日でない場合、次回更新日を計算
        }
        
        // 正常な場合はサブスクリプションを追加
        share.recordSubscriptionData(name: title, genre: genre[genreSelection], price: Int(fee) ?? 0, plan: plan[planSelection], startDate: next, paymentMethod: selectKey, isActive: true)
        
        dismiss()
    }

    
    func sortedPaymentMethods() -> [(key: String, value: PaymentMethodDetail)] {
        return share.paymentMethod.sorted { first, second in
            let firstIndex = methodDescription.firstIndex(of: first.value.details) ?? Int.max
            let secondIndex = methodDescription.firstIndex(of: second.value.details) ?? Int.max
            
            return firstIndex < secondIndex
        }
    }
}
