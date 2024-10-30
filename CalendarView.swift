import SwiftUI

struct CalendarView: View {
    @ObservedObject var share: ShareContent
    
    @State private var selectedDate = Date()
    @State private var currentMonth: Date = Date()

    let calendar = Calendar.current

    var firstOfMonth: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) ?? Date()
    }

    var startDayOfWeek: Int {
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        return firstWeekday - 1
    }

    var daysInMonth: [Date] {
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth) ?? 1..<31
        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 5) {
                HStack {
                    Button(action: {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .foregroundStyle(share.themeColor)
                    }
                    Spacer()
                    Text(monthYearString(for: currentMonth))
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .foregroundStyle(share.themeColor)
                    }
                }
                .padding(.vertical, 8.0)
                .padding(.horizontal, 10.0)

                HStack {
                    ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { day in
                        Text(day)
                            .foregroundStyle(day == "日" ? Color.red : (day == "土" ? Color.blue : Color.black))
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                    ForEach(0..<startDayOfWeek, id: \.self) { _ in
                        Text("")
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(daysInMonth, id: \.self) { date in
                        let day = calendar.component(.day, from: date)
                        let weekday = calendar.component(.weekday, from: date)
                        
                        ZStack(alignment: .topTrailing) {
                            Text("\(day)")
                                .frame(maxWidth: .infinity)
                                .background(calendar.isDate(date, inSameDayAs: selectedDate) ? share.themeColor : (weekday == 1 ? Color.red.opacity(0.3) : (weekday == 7 ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3))))
                                .cornerRadius(8)
                                .onTapGesture {
                                    selectedDate = date
                                }
                            VStack(spacing:0) {
                                if hasPaymentRecord(for: date) {
                                    Circle()
                                        .foregroundStyle(.red)  // 支払いがある日は赤いサークル
                                        .frame(width: 10, height: 10)
                                }
                                if hasIncomeRecord(for: date) {
                                    Circle()
                                        .foregroundStyle(.blue)  // 収入がある日は青いサークル
                                        .frame(width: 10, height: 10)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 1.0)
                }
                .padding(5.0)
                
                ZStack(alignment: .topLeading) {
                    let selectedWeekday = calendar.component(.weekday, from: selectedDate)
                    Rectangle()
                        .foregroundStyle(selectedWeekday == 1 ? Color.red.opacity(0.3) : (selectedWeekday == 7 ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3)))
                        .frame(height: 20)
                        .border(.black.opacity(0.2))
                    Text(selectedDateString())
                        .padding(.leading, 4.0)
                }
                
                List {
                    let totalPaymentAmount = share.paymentMethod.keys.reduce(0) { $0 + calculateTotalAmount(for: $1) }
                    let totalIncomeAmount = share.incomeMethod.reduce(0) { $0 + calculateTotalAmount(for: $1) }
                    
                    if totalPaymentAmount == 0 && totalIncomeAmount == 0 {
                        Text("記録がありません")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(Array(share.paymentMethod.keys), id: \.self) { method in
                            let totalAmount = calculateTotalAmount(for: method)
                            let totalPoint = share.getTotalPointByMethod(method: method, date: selectedDate)
                            if totalAmount != 0 {
                                NavigationLink(destination: DetailView(share: share, genre: "出金", method: method, selectedDate: selectedDate)) {
                                    HStack {
                                        Text(method)
                                        Spacer()
                                        Text("-\(totalAmount)円")
                                            .foregroundColor(.red)
                                    }
                                }
                                if totalPoint != 0 {
                                    HStack {
                                        Text("\(method)ポイント")
                                        Spacer()
                                        Text("+\(totalPoint)pt")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        
                        ForEach(share.incomeMethod, id: \.self) { method in
                            let totalAmount = calculateTotalAmount(for: method)
                            if totalAmount != 0 {
                                NavigationLink(destination: DetailView(share: share, genre: "入金", method: method, selectedDate: selectedDate)) {
                                    HStack {
                                        Text(method)
                                        Spacer()
                                        Text("+\(totalAmount)円")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                Spacer()
            }
            .navigationBarTitle("カレンダー", displayMode: .inline)
        }
        .tint(.blue)
    }

    func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        return formatter.string(from: date)
    }
    
    func selectedDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日(EEE)"
        return formatter.string(from: selectedDate)
    }
    
    func calculateTotalAmount(for method: String) -> Int {
        let records = share.getAllRecords()
        return records.filter { $0.method == method && Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            .reduce(0) { $0 + $1.amount }
    }

    // 支払い記録があるか確認するメソッド
    func hasPaymentRecord(for date: Date) -> Bool {
        let records = share.getAllRecords()
        return records.contains { Calendar.current.isDate($0.date, inSameDayAs: date) && $0.type == "出金" }
    }

    // 収入記録があるか確認するメソッド
    func hasIncomeRecord(for date: Date) -> Bool {
        let records = share.getAllRecords()
        return records.contains { Calendar.current.isDate($0.date, inSameDayAs: date) && $0.type == "入金" }
    }
}

