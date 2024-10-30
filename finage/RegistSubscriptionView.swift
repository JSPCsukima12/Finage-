import SwiftUI
import RealmSwift

struct RegistSubscriptionView: View {
    @ObservedObject var share: ShareContent
    @State private var showAddSubscriptionSheet = false  // 新しいサブスクリプションを追加するシートの表示状態
    @State private var showDeleteSubscriptionSheet = false // 削除確認シートの表示状態
    
    var body: some View {
        VStack {
            if share.subscriptionData.isEmpty {
                Text("サブスクリプションが登録されていません")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    ForEach(share.subscriptionData.indices, id: \.self) { index in
                        SubscriptionView(share: share, subscription: share.subscriptionData[index], index: index)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationBarTitle("サブスク管理", displayMode: .inline)
        .toolbarBackground(share.themeColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            if !share.subscriptionData.isEmpty { // サブスクリプションが存在する場合のみ表示
                Button(action: {
                    showDeleteSubscriptionSheet = true // ゴミ箱ボタンを押した時にシートを表示
                }) {
                    Image(systemName: "trash.fill")
                }
                .foregroundStyle(.red)
            }
            
            // プラスアイコンのボタン
            Button(action: {
                showAddSubscriptionSheet = true
            }) {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showAddSubscriptionSheet) {
            AddSubscriptionView(share: share)
        }
        .sheet(isPresented: $showDeleteSubscriptionSheet) {
            DeleteSubscriptionView(share: share) // 削除確認シート
        }
    }
}

struct SubscriptionView: View {
    @ObservedObject var share: ShareContent
    var subscription: SubscriptionData
    var index: Int

    var body: some View {
        Button(action: {
            toggleSubscription(subscription) 
        }) {
            HStack {
                Circle()
                    .foregroundStyle(subscription.isActive ? .blue : .red)
                    .frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text(subscription.name)
                            .font(.headline)
                            .bold()
                        Spacer()
                        Image(systemName: share.genreToIMmageName(subscription.genre))
                    }
                    HStack {
                        Text("開始日時: \(formattedDate(subscription.startDate))~")
                        Spacer()
                        Text("\(subscription.price)円")
                            .underline()
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
                    share.loadSubscriptions()
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
        
        // 正常な場合はサブスクリプションを追加
        share.recordSubscriptionData(name: title, genre: genre[genreSelection], price: Int(fee) ?? 0, plan: plan[planSelection], startDate: startDate, paymentMethod: selectKey, isActive: true)
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




struct DeleteSubscriptionView: View {
    @ObservedObject var share: ShareContent
    @State private var selectedSubscriptions: Set<Int> = [] // 選択されたサブスクリプションのインデックスを管理
    @Environment(\.dismiss) var dismiss // シートを閉じるための環境変数
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("\(selectedSubscriptions.count)件選択中")
                    Spacer()
                    Button("削除") {
                        deleteSelectedSubscriptions(selectedSubscriptions: selectedSubscriptions) // 選択されたサブスクリプションを削除
                    }
                    .foregroundColor(selectedSubscriptions.isEmpty ? .gray : .red) // 選択が0の場合はgray
                    .disabled(selectedSubscriptions.isEmpty) // 選択されていない場合は無効化
                    
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                .padding(.top, 10)
                .padding(.horizontal, 7.0)
                
                List {
                    ForEach(share.subscriptionData.indices, id: \.self) { index in
                        HStack {
                            Button(action: {
                                toggleSelection(for: index) // チェックボックスのトグルアクション
                            }) {
                                Image(systemName: selectedSubscriptions.contains(index) ? "checkmark.square" : "square")
                                    .foregroundColor(selectedSubscriptions.contains(index) ? .blue : .gray)
                            }
                            
                            Image(systemName: share.genreToIMmageName(share.subscriptionData[index].genre))
                            Text(share.subscriptionData[index].name) // サブスクリプションの名前を表示
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarTitle("サブスクリプション削除", displayMode: .inline)
        }
    }
    
    private func toggleSelection(for index: Int) {
        if selectedSubscriptions.contains(index) {
            selectedSubscriptions.remove(index) // すでに選択されている場合は選択を解除
        } else {
            selectedSubscriptions.insert(index) // 選択されていない場合は選択する
        }
    }
    
    func deleteSelectedSubscriptions(selectedSubscriptions: Set<Int>) {
        let realm = try! Realm()
        
        // 削除対象のサブスクリプションを一時的に保存
        let subscriptionsToDelete = selectedSubscriptions.compactMap { index in
            return share.subscriptionData[index]
        }
        
        // Realmのトランザクションで削除処理を行う
        try! realm.write {
            for subscription in subscriptionsToDelete { // 一時的に保存したサブスクリプションを削除
                realm.delete(subscription)
            }
        }
        
        // 削除後に再度サブスクリプションデータをロード
        share.loadSubscriptions()
        dismiss()
    }
}


