import SwiftUI

struct RecordView: View {
    @ObservedObject var share: ShareContent
    
    @State private var menu: [String] = ["出金記録", "入金記録"]
    @State private var menuSelection: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                Picker("", selection: $menuSelection) {
                    ForEach(0..<menu.count, id: \.self) { index in
                        Text(menu[index])
                            .tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                if menuSelection == 0 {
                    RecordComponent(share: share, text: "支払い方法")
                } else {
                    RecordComponent(share: share, text: "収入形態")
                }
                Spacer()
                BannerAdView()
                    .padding(.bottom,110.0)
            }
            .padding(10.0)
            .ignoresSafeArea(.all, edges: .bottom)
            .navigationBarTitle("記録", displayMode: .inline)
            .toolbar {
                if menuSelection == 0 {
                    NavigationLink(destination: AddMethod(share: share, text: "支払い方法")) {
                        Image(systemName: "creditcard.fill")
                    }
                } else {
                    NavigationLink(destination: AddMethod(share: share, text: "収入形態")) {
                        Image(systemName: "banknote")
                    }
                }
            }
        }
        .tint(.blue)
    }
}

struct RecordComponent: View {
    @ObservedObject var share: ShareContent
    
    let text: String
    @State private var fee: String = ""
    @State private var selectKey: String = "" // 支払い方法や収入形態のキーを選ぶための変数
    @State private var memo: String = ""
    @State private var selectedDate: Date = Date()
    
    @State private var methodDescription: [String] = ["現金払い", "クレジットカード", "QR決済", "電子マネー", "その他"] // ソート順を指定
    
    // アラート表示を管理するためのState
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var pointsEarned: Int = 0 // 獲得ポイントを保持する変数

    var body: some View {
        VStack(spacing: 10) {
            Divider()
            
            DatePicker("日付", selection: $selectedDate, displayedComponents: .date)

            Divider()
            
            HStack {
                Text(text)
                Spacer()
                Picker(text, selection: $selectKey) {
                    Text("--選択してください--")
                    
                    if text == "支払い方法" {
                        // 支払い方法をソートして表示
                        ForEach(sortedPaymentMethods(), id: \.key) { key, value in
                            HStack(spacing:3) {
                                Image(systemName:share.methodToImageName(value.details))
                                Text(key)
                            }
                        }
                    } else {
                        // 収入形態をソートして表示
                        ForEach(share.incomeMethod.sorted(), id: \.self) { method in
                            HStack(spacing:3) {
                                Image(systemName:share.methodToImageName(method))
                                Text(method)
                            }
                        }
                    }
                }
                .pickerStyle(MenuPickerStyle()) // ピッカーの見た目を変更
            }
            
            Divider()
            
            HStack {
                Text("金額")
                Spacer()
                CustomTextFieldWithToolbar(text: $fee, placeholder: "金額を入力", keyboardType: .numberPad, onCommit: {
                    // Handle onCommit actions if needed
                })
                .frame(height:15)
                Text("円")
            }
            
            Divider()
            
            // 獲得ポイントを計算
            if let methodDetail = share.paymentMethod[selectKey], methodDetail.earnsPoints {
                HStack {
                    Text("ポイント:")
                    Spacer()
                    Text(" \(calculatePoints())pt")
                }
                .foregroundColor(.green)
                Divider()
            }

            HStack {
                Text("メモ")
                Spacer()
                TextField("メモを入力",text:$memo)
                    .multilineTextAlignment(.trailing)
            }
            
            Divider()
            
            Button(action: {
                // 入力チェック
                if selectKey.isEmpty {
                    alertMessage = "\(text)を選択してください。"
                    showAlert = true
                } else if fee.isEmpty  {
                    alertMessage = "金額を入力してください。"
                    showAlert = true
                } else if Int(fee) == 0 {
                    alertMessage = "金額は1円以上にしてください。"
                    showAlert = true
                } else {
                    let amount = Int(fee) ?? 0
                    
                    if text == "支払い方法" {
                        share.saveRecord(date: selectedDate, type: "出金", method: selectKey, amount: amount, memo: memo)
                    } else {
                        share.saveRecord(date: selectedDate, type: "入金", method: selectKey, amount: amount, memo: memo)
                    }
                    
                    // ポイントを計算して表示
                    if let methodDetail = share.paymentMethod[selectKey], methodDetail.earnsPoints {
                        pointsEarned = (amount / methodDetail.baseFee) // 獲得ポイントの計算
                    }
                    
                    // 入力後にリセット
                    selectKey = ""
                    fee = ""
                    memo = ""
                    
                }
            }) {
                Text("記録する")
                    .bold()
                    .foregroundColor(.white)
                    .padding(.vertical, 10.0)
                    .padding(.horizontal, 18.0)
                    .background(share.themeColor)
                    .cornerRadius(8)
            }
            // アラートの設定
            .alert(isPresented: $showAlert) {
                Alert(title: Text("入力エラー"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // 獲得ポイントを計算するメソッド
    private func calculatePoints() -> Int {
        guard let methodDetail = share.paymentMethod[selectKey] else { return 0 }
        return (Int(fee) ?? 0) / methodDetail.baseFee // baseFeeに基づいてポイント計算
    }
    
    // 支払い方法をmethodDescriptionの順にソートするメソッド
    func sortedPaymentMethods() -> [(key: String, value: PaymentMethodDetail)] {
        // methodDescriptionの順で支払い方法をソート
        return share.paymentMethod.sorted { first, second in
            let firstIndex = methodDescription.firstIndex(of: first.value.details) ?? Int.max
            let secondIndex = methodDescription.firstIndex(of: second.value.details) ?? Int.max
            
            // methodDescriptionで定義された順序に従ってソート
            return firstIndex < secondIndex
        }
    }
}

