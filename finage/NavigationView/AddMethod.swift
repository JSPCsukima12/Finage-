import SwiftUI
import RealmSwift

struct AddMethod: View {
    @ObservedObject var share: ShareContent
    
    let text: String
    @State private var showingSheet = false
    @State private var methodDescription: [String] = ["現金払い", "クレジットカード", "QR決済", "電子マネー", "その他"]
    
    // EditMode を環境変数として使用
    @Environment(\.editMode) var editMode
    
    var body: some View {
        List {
            if text == "支払い方法" {
                ForEach(sortedPaymentMethods(), id: \.key) { key, value in
                    HStack {
                        // 編集モード時に現金以外に-ボタンを表示
                        if editMode?.wrappedValue == .active && key != "現金" {
                            Button(action: {
                                deletePaymentItem(key: key)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        
                        if value.earnsPoints {
                            NavigationLink(destination: ChangePointsDetailView(share: share, methodName: key, methodDetail: value)) {
                                HStack {
                                    HStack(spacing: 3) {
                                        Text(key)
                                        Image(systemName: "p.circle")
                                            .foregroundColor(.blue)
                                    }
                                    Spacer()
                                    HStack(spacing: 3) {
                                        Image(systemName: share.methodToImageName(value.details))
                                        Text(value.details)
                                    }
                                    .foregroundColor(.gray)
                                }
                            }
                        } else {
                            HStack {
                                Text(key)
                                Spacer()
                                HStack(spacing: 3) {
                                    Image(systemName: share.methodToImageName(value.details))
                                    Text(value.details)
                                }
                                .foregroundColor(.gray)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        // スワイプ削除は現金以外
                        if key != "現金" {
                            Button(role: .destructive) {
                                deletePaymentItem(key: key)
                            } label: {
                                Text("削除")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            } else {
                ForEach(share.incomeMethod, id: \.self) { element in
                    HStack {
                        // 編集モード時に給料以外に-ボタンを表示
                        if editMode?.wrappedValue == .active && element != "給料" {
                            Button(action: {
                                deleteIncomeItem(element: element)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        
                        HStack(spacing: 3) {
                            Image(systemName: share.methodToImageName(element))
                            Text(element)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        // スワイプ削除は給料以外
                        if element != "給料" {
                            Button(role: .destructive) {
                                deleteIncomeItem(element: element)
                            } label: {
                                Text("削除")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }
            
            Button(action: {
                showingSheet.toggle()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("\(text)を追加する")
                }
            }
            .foregroundStyle(.blue)
        }
        .listStyle(PlainListStyle())
        .padding(.vertical, 5.0)
        .navigationBarTitle("\(text)一覧", displayMode: .inline)
        .toolbarBackground(share.themeColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showingSheet) {
            AddMethodSheetView(share: share, text: text)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton() // Editボタン
            }
        }
    }
    
    // 支払い方法の削除処理
    func deletePaymentItem(key: String) {
        share.deleteRecordsByMethod(method: key)
        share.paymentMethod.removeValue(forKey: key)
    }

    // 収入方法の削除処理（給料以外を削除可能にする）
    func deleteIncomeItem(element: String) {
        if let index = share.incomeMethod.firstIndex(of: element), element != "給料" { // 給料は削除しない
            share.incomeMethod.remove(at: index)
        }
    }
    
    // 支払い方法をmethodDescriptionの順にソートするメソッド
    func sortedPaymentMethods() -> [(key: String, value: PaymentMethodDetail)] {
        return share.paymentMethod.sorted { first, second in
            let firstIndex = methodDescription.firstIndex(of: first.value.details) ?? methodDescription.count
            let secondIndex = methodDescription.firstIndex(of: second.value.details) ?? methodDescription.count
            return firstIndex < secondIndex
        }
    }
}


struct ChangePointsDetailView: View {
    @ObservedObject var share: ShareContent
    let methodName: String
    @State private var baseFee: String
    @State private var changeFee: String = ""
    
    @Environment(\.dismiss) var dismiss

    init(share: ShareContent, methodName: String, methodDetail: PaymentMethodDetail) {
        self.share = share
        self.methodName = methodName
        // 初期値として methodDetail の基準金額をセット
        self._baseFee = State(initialValue: "\(methodDetail.baseFee)")
    }
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: share.methodToImageName(share.paymentMethod[methodName]?.details ?? methodName))
                    .resizable()
                    .frame(width: (share.methodToImageName(share.paymentMethod[methodName]?.details ?? methodName) == "creditcard" || share.methodToImageName(share.paymentMethod[methodName]?.details ?? methodName) == "banknote") ? 45 : 30, height: 30)
                Text(methodName)
                    .font(.largeTitle)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.5), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .padding(.horizontal)
            
            List {
                HStack {
                    Text("現在の基準金額:")
                    Spacer()
                    Text("\(baseFee)円")
                }
                HStack {
                    Text("新しい基準金額:")
                    Spacer()
                    CustomTextFieldWithToolbar(text: $changeFee, placeholder: "基準金額", keyboardType: .numberPad, onCommit: {
                        
                    })
                    .frame(height:15)
                    Text("円")
                }
            }
            .listStyle(PlainListStyle())
            .frame(height:80)
            
            // 保存ボタンを追加
            Button(action: {
                // 入力値を整数に変換して保存
                if let newBaseFee = Int(changeFee) {
                    // 変更をshareオブジェクトに反映
                    share.paymentMethod[methodName]?.baseFee = newBaseFee
                    // 保存処理（必要ならRealm等に保存）
                    share.savePaymentMethod()
                    dismiss()
                }
            }) {
                Text("保存する")
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.top)
            
            BannerAdView()
                .padding(.bottom,60.0)
            
            Spacer()
        }
        .padding(.horizontal,5.0)
        .padding(.vertical,15.0)
        .navigationTitle("ポイント基準金額変更")
        .toolbarBackground(share.themeColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}


struct AddMethodSheetView: View {
    @ObservedObject var share: ShareContent
    
    let text: String
    @State private var methodName: String = "" // 支払い方法名
    @State private var methodDescription: [String] = ["現金払い", "クレジットカード", "QR決済", "電子マネー", "その他"]
    @State private var selection: Int = 0
    @State private var pointBool: Bool = false
    @State private var basefee: String = ""
    
    @Environment(\.dismiss) var dismiss

    // アラート表示用のState変数
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        NavigationStack {
            Form {
                // 支払い方法の名前と説明を入力
                HStack {
                    Text("名前")
                    Spacer()
                    TextField("\(text)の名前", text: $methodName)
                        .multilineTextAlignment(.trailing)
                }
                if text == "支払い方法" {
                    Picker("詳細", selection: $selection) {
                        ForEach(0..<methodDescription.count, id: \.self) { index in
                            Text(methodDescription[index])
                                .tag(index)
                        }
                    }
                }
                if text == "支払い方法" {
                    Toggle("ポイント獲得", isOn: $pointBool)
                        .toggleStyle(CustomToggleStyle(onColor: share.themeColor, offColor: .gray))
                    if pointBool {
                        HStack {
                            Text("ポイント基準金額")
                            Spacer()
                            CustomTextFieldWithToolbar(text: $basefee, placeholder: "金額", keyboardType: .numberPad, onCommit: {
                                // Handle onCommit actions if needed
                            })
                            .frame(height:15)
                            Text("円")
                        }
                    }
                }
                Button("追加する") {
                    // 入力チェックを追加
                    if methodName.isEmpty {
                        alertMessage = "支払い方法名は必須です。"
                        showAlert = true
                    } else if pointBool && basefee.isEmpty {
                        alertMessage = "ポイント獲得基準を入力してください。"
                        showAlert = true
                    } else if pointBool && Int(basefee) == 0 {
                        alertMessage = "ポイント獲得基準が0円になっています。"
                        showAlert = true
                    } else {
                        if text == "支払い方法" {
                            let details = methodDescription[selection]
                            share.paymentMethod[methodName] = PaymentMethodDetail(method: methodName, details: details, earnsPoints: pointBool, baseFee: Int(basefee) ?? 0)
                        } else {
                            share.incomeMethod.append(methodName)
                        }
                        dismiss()
                    }
                }
            }
            .navigationBarTitle("\(text)の追加", displayMode: .inline)
            .toolbarBackground(share.themeColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarItems(leading: Button("閉じる") {
                dismiss()
            })
            // アラートを追加
            .alert(isPresented: $showAlert) {
                Alert(title: Text("入力エラー"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
}
