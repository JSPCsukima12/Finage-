import SwiftUI
import RealmSwift

struct DetailView: View {
    @ObservedObject var share: ShareContent
    let genre: String
    let method: String
    let selectedDate: Date

    @Environment(\.editMode) var editMode 

    var body: some View {
        VStack(spacing: 10) {
            let records = share.getRecordsByMethod(genre: genre, method: method, on: selectedDate)
            
            HStack {
                Text(formattedDate(selectedDate))
                    .bold()
                    .underline()
                Spacer()
            }
            
            HStack {
                HStack {
                    Image(systemName: share.methodToImageName(share.paymentMethod[method]?.details ?? method))
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
                
                Text("計: \(totalAmount(for: records))円")
                    .font(.title2)
                    .underline()
            }

            List {
                ForEach(records, id: \.id) { record in
                    HStack {
                        Text(record.memo.isEmpty ? "Unknown" : record.memo)
                            .font(.headline)
                        Spacer()
                        Text("\(record.amount)円")
                            .foregroundColor(record.type == "出金" ? .red : .blue)
                    }
                    if record.points != 0 {
                        HStack {
                            Text("---獲得ポイント:")
                            Spacer()
                            Text("\(record.points)pt")
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .onDelete(perform: deleteRecord) // Enable delete in edit mode
            }
            .listStyle(PlainListStyle())
        }
        .padding(.vertical, 10.0)
        .padding(.horizontal, 5.0)
        .navigationBarTitle("詳細", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton() // Edit button placed in the toolbar
            }
        }
        .environment(\.editMode, editMode) // Apply edit mode to the list
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日(EEE)"  // 曜日も含むフォーマット
        formatter.locale = Locale(identifier: "ja_JP")  // 日本語の曜日を取得
        return formatter.string(from: date)
    }

    private func totalAmount(for records: [PaymentRecord]) -> Int {
        return records.reduce(0) { $0 + $1.amount }
    }

    private func deleteRecord(at offsets: IndexSet) {
        offsets.forEach { index in
            let record = share.getRecordsByMethod(genre: genre, method: method, on: selectedDate)[index]
            if let realm = record.realm {
                do {
                    try realm.write {
                        realm.delete(record)
                    }
                    share.objectWillChange.send()
                } catch {
                    print("Error deleting record: \(error)")
                }
            }
        }
    }
}
