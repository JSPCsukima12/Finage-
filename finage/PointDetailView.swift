import SwiftUI
import RealmSwift

struct PointDetailView: View {
    @ObservedObject var share: ShareContent
    let method: String // 支払い方法を受け取る
    @State private var records: Results<PaymentRecord>? // 支払い記録を保持するプロパティ
    
    var body: some View {
        VStack {
            if let records = records {
                let filteredRecords = records.filter { $0.points >= 1 } // ポイントが1以上のレコードをフィルタ
                    .sorted(by: { $0.date < $1.date }) // 日付の昇順でソート
                
                HStack {
                    Image(systemName: share.methodToImageName(share.paymentMethod[method]?.details ?? method)) // methodを使用
                        .resizable()
                        .frame(width: (share.methodToImageName(share.paymentMethod[method]?.details ?? method) == "creditcard" || share.methodToImageName(share.paymentMethod[method]?.details ?? method) == "banknote") ? 45 : 30, height: 30)
                    Text(method)
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
                
                if filteredRecords.isEmpty {
                    Text("ポイントが1以上の支払い記録はありません。")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(filteredRecords, id: \.id) { record in
                        HStack {
                            // 日付を表示
                            Text(record.date, style: .date) // デフォルトの日付スタイル
                                .font(.headline)
                            Spacer()
                            Text("\(record.points)pt")
                                .foregroundColor(.blue)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
        }
        .padding(.horizontal,5.0)
        .padding(.vertical,10.0)
        .navigationBarTitle("ポイント獲得履歴", displayMode: .inline)
        .onAppear {
            // ここで支払い記録を取得
            let allRecords = share.getAllRecords()
            self.records = allRecords.filter("method == %@", method) // 選択されたmethodでフィルタ
        }
    }
}
