import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    private let adUnitID = "ca-app-pub-3940256099942544/2435281174" // 実際のバナー広告ユニットIDを入力
    private let customHeight: CGFloat = 250 // カスタムの高さ

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: BannerAdView
        var bannerView: GADBannerView

        init(_ parent: BannerAdView) {
            self.parent = parent

            // カスタムサイズを指定
            let adSize = GADAdSizeFromCGSize(CGSize(width: 300, height: parent.customHeight))
            
            // バナー広告の設定
            self.bannerView = GADBannerView(adSize: adSize)
            self.bannerView.adUnitID = parent.adUnitID
        }
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        // 正しいウィンドウシーンを取得し、rootViewControllerを設定
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            context.coordinator.bannerView.rootViewController = windowScene.windows.first?.rootViewController
        }

        // バナーをビューに追加
        context.coordinator.bannerView.load(GADRequest())
        context.coordinator.bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(context.coordinator.bannerView)

        // レイアウトの設定
        NSLayoutConstraint.activate([
            context.coordinator.bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            context.coordinator.bannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            context.coordinator.bannerView.widthAnchor.constraint(equalToConstant: 300), // 幅を指定
            context.coordinator.bannerView.heightAnchor.constraint(equalToConstant: customHeight) // 高さを指定
        ])

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // 必要であればここに更新処理を記述
    }
}
