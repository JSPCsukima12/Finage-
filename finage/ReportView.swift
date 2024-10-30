import SwiftUI
import RealmSwift
import Charts

struct ReportView: View {
    @ObservedObject var share: ShareContent
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    HStack {
                        Text("収支割合")
                            .bold()
                            .underline()
                        Spacer()
                    }
                    AnalysisComponent(share: share)
                    
                    HStack {
                        Text("支払い方法別使用金額")
                            .bold()
                            .underline()
                        Spacer()
                    }
                    GraphComponent(share: share)
                    
                    // 獲得ポイントセクションの表示条件
                    let hasEarningPoints = share.paymentMethod.values.contains { $0.earnsPoints }
                    if hasEarningPoints {
                        HStack {
                            Text("総獲得ポイント")
                                .bold()
                                .underline()
                            Spacer()
                        }
                        let pointsByMethod = share.aggregatePointsByMethod()
                        PointComponent(share: share, pointsByMethod: pointsByMethod)
                    }
                    Spacer(minLength: 20) // 必要に応じて高さを調整
                    BannerAdView()
                        .padding(.top, 270.0) // 広告の高さを設定
                        .padding(.bottom, 10.0)
                }
                .padding(5.0)
                .navigationBarTitle("分析", displayMode: .inline)
            }
        }
        .tint(.blue)
    }
}


struct AnalysisComponent: View {
    @ObservedObject var share: ShareContent

    var body: some View {
        let (income, expense) = share.calculateIncomeAndExpense()
        let total = income + expense
        
        // パーセンテージを計算
        let incomePercentage = total > 0 ? Double(income) / Double(total) * 100 : 0
        let expensePercentage = total > 0 ? Double(expense) / Double(total) * 100 : 0
        
        let incomeExpenseData: [(String, Double)] = total > 0 ? [("支出", expensePercentage), ("収入", incomePercentage)] : [("支出", 100), ("収入", 0)] // 記録がない場合、支出を100%に
        
        VStack {
            // グラフ
            Chart {
                ForEach(incomeExpenseData, id: \.0) { data in
                    BarMark(
                        x: .value("Amount", data.1)
                    )
                    .foregroundStyle(total == 0 ? .gray.opacity(0.6) : (data.0 == "収入" ? .blue.opacity(0.7) : .red.opacity(0.9)))
                    .annotation(position:.overlay) {
                        // 記録があるときのみパーセンテージを表示
                        if total > 0 && data.1 > 0 { // パーセンテージが0より大きいときのみ表示
                            Text(String(format: "%.0f%%", data.1)) // パーセンテージを表示
                                .font(.caption)
                                .foregroundStyle(.black) // 色を設定
                        } else {
                            EmptyView() // 記録がない場合は何も表示しない
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 20)) { value in
                    // ラベルをパーセント表示
                    if let percentage = value.as(Double.self) {
                        AxisValueLabel("\(Int(percentage))%")
                    }
                }
            }
            .chartYAxis(.hidden) // Y軸を非表示にする
            .frame(height: 50) // グラフの高さを設定

            // 凡例 (レジェンド)
            HStack(spacing: 10) {
                HStack(spacing: 3) {
                    Circle()
                        .fill(Color.red.opacity(0.8))
                        .frame(width: 6, height: 6)
                    Text("支出(\(expense)円)")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                }
                HStack(spacing: 3) {
                    Circle()
                        .fill(Color.blue.opacity(0.7))
                        .frame(width: 6, height: 6)
                    Text("収入(\(income)円)")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                }
                Spacer()
            }
            .padding(.top, 0)
            .padding(.horizontal, 6.0)
        }
    }
}


struct GraphComponent: View {
    @ObservedObject var share: ShareContent
    @State private var methodDescription: [String] = ["現金払い", "クレジットカード", "QR決済", "電子マネー", "その他"]

    private let colorMapping: [String: Color] = [
        "現金払い": .yellow.opacity(0.5),
        "クレジットカード": .green.opacity(0.9),
        "QR決済": .red.opacity(0.8),
        "電子マネー": .pink.opacity(0.4),
        "その他": .gray
    ]

    let columns = [
        GridItem(.flexible()), // 1列目
        GridItem(.flexible()), // 2列目
        GridItem(.flexible())  // 3列目
    ]

    var body: some View {
        let maxFee = share.methodData
            .compactMap { Double($0.fee) }
            .max() ?? 0

        VStack(spacing: 0) {
            Chart {
                ForEach(sortedPaymentMethods(), id: \.key) { method in
                    let fee = feeForMethod(method: method.key)
                    let description = method.value.details

                    BarMark(
                        x: .value("支払い方法", method.key),
                        y: .value("支払い合計金額", fee > 0 ? fee : 0.0)
                    )
                    .foregroundStyle(colorMapping[description] ?? .black)
                    .annotation(position: .top) {
                        Text("¥\(fee > 0 ? Int(fee).formattedWithSeparator : "0")")
                            .font(.caption)
                            .foregroundColor(.black)
                            .offset(y: -5)
                    }
                }
            }
            .chartYScale(domain: 0...(maxFee + 1000))
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisTick(stroke: StrokeStyle(lineWidth: 1))
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisTick(stroke: StrokeStyle(lineWidth: 1))
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    AxisValueLabel()
                }
            }
            .frame(height: 160)

            // LazyVGridを使った凡例の追加
            LazyVGrid(columns: columns, spacing:3) {
                ForEach(methodDescription, id: \.self) { method in
                    HStack(spacing: 3) {
                        Circle()
                            .fill(colorMapping[method] ?? .black)
                            .frame(width: 6, height: 6)
                        Text(method)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .foregroundColor(.gray)
                            .font(.footnote)
                        Spacer()
                    }
                }
            }
            .padding(.top,8)
        }
        .padding(.top, 0)
        .padding(.horizontal, 6.0)
    }
    
    func feeForMethod(method: String) -> Double {
        return share.methodData
            .filter { $0.paymentName == method }
            .compactMap { Double($0.fee) }
            .reduce(0, +)
    }
    
    func sortedPaymentMethods() -> [(key: String, value: PaymentMethodDetail)] {
        return share.paymentMethod.sorted { first, second in
            let firstIndex = methodDescription.firstIndex(of: first.value.details) ?? Int.max
            let secondIndex = methodDescription.firstIndex(of: second.value.details) ?? Int.max
            return firstIndex < secondIndex
        }
    }
}

struct PointComponent: View {
    @ObservedObject var share: ShareContent
    @State private var methodDescription: [String] = ["現金払い", "クレジットカード", "QR決済", "電子マネー", "その他"]
    var pointsByMethod: [String: Int]

    var body: some View {
        let columns = [
            GridItem(.fixed(180)),
            GridItem(.fixed(180))
        ]
        
        // Sort pointsByMethod by methodDescription and maintain all methods separately
        let sortedMethods = pointsByMethod.keys.sorted { (method1, method2) -> Bool in
            let detail1 = share.paymentMethod[method1]?.details ?? ""
            let detail2 = share.paymentMethod[method2]?.details ?? ""
            let index1 = methodDescription.firstIndex(of: detail1) ?? methodDescription.count
            let index2 = methodDescription.firstIndex(of: detail2) ?? methodDescription.count
            return index1 < index2
        }
        
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(sortedMethods, id: \.self) { method in
                if let totalPoints = pointsByMethod[method] {
                    if totalPoints > 0 {
                        NavigationLink(destination: PointDetailView(share: share, method: method)) { // methodを渡す
                            HStack {
                                let imageName = share.methodToImageName(share.paymentMethod[method]?.details ?? "")
                                let imageWidth: CGFloat = imageName == "creditcard" ? 50 : 40
                                
                                Image(systemName: imageName)
                                    .resizable()
                                    .frame(width: imageWidth, height: 40)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 0) {
                                    Text(method)
                                        .bold()
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                    Text("\(totalPoints)pt")
                                }
                                Image(systemName:"chevron.right")
                            }
                            .frame(width: 140, height: 40)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .foregroundStyle(.black)
                    } else {
                        HStack {
                            let imageName = share.methodToImageName(share.paymentMethod[method]?.details ?? "")
                            let imageWidth: CGFloat = imageName == "creditcard" ? 50 : 40
                            
                            Image(systemName: imageName)
                                .resizable()
                                .frame(width: imageWidth, height: 40)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 0) {
                                Text(method)
                                    .bold()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                Text("0pt")
                            }
                        }
                        .frame(width: 140, height: 40)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .foregroundStyle(.black)
                    }
                }
            }
        }
        .padding(.horizontal,0)
        .padding(.vertical, 4)
    }
}



extension Int {
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
