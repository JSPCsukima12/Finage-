import SwiftUI
import WebKit

struct PrivacyPolicyView: View {
    @ObservedObject var share: ShareContent
    
    var body: some View {
        let privacyPolicyHTML = """
        <!DOCTYPE html>
            <html>
            <head>
              <meta charset='utf-8'>
              <meta name='viewport' content='width=device-width'>
              <title><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">プライバシーポリシー</font></font></title>
              <style> body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; padding:1em; } </style>
            </head>
            <body>
            <strong><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">プライバシーポリシー</font></font></strong><p><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">このプライバシーポリシーは、Shogo Teramoto (以下「サービスプロバイダー」) が広告サポートサービスとして作成したモバイルデバイス用の Finage+ アプリ (以下「アプリケーション」) に適用されます。このサービスは「現状のまま」の使用を意図しています。</font></font></p><br><strong><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">情報の収集と使用</font></font></strong><p><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">アプリケーションはダウンロードして使用する際に情報を収集します。この情報には次のような情報が含まれる場合があります。</font></font></p><ul><li><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">デバイスのインターネット プロトコル アドレス (例: IP アドレス)</font></font></li><li><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">あなたがアクセスしたアプリケーションのページ、アクセスした日時、それらのページで費やした時間</font></font></li><li><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">アプリケーションに費やした時間</font></font></li><li><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">モバイルデバイスで使用するオペレーティングシステム</font></font></li></ul><p></p><br><p><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">アプリケーションは、モバイルデバイスの位置情報に関する正確な情報を収集しません。</font></font></p><div style="display: none;"><p><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">アプリケーションはデバイスの位置情報を収集します。これにより、サービスプロバイダーはユーザーのおおよその地理的位置を特定し、以下の方法で利用することができます。</font></font></p><ul><li><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">地理位置情報サービス: サービスプロバイダーは、位置データを活用して、パーソナライズされたコンテンツ、関連性の高い推奨事項、位置情報ベースのサービスなどの機能を提供します。</font></font></li><li><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">分析と改善: 集約され匿名化された位置データは、サービス プロバイダーがユーザーの行動を分析し、傾向を特定し、アプリケーションの全体的なパフォーマンスと機能を向上させるのに役立ちます。</font></font></li><li><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">サードパーティのサービス: サービス プロバイダーは定期的に匿名化された位置データを外部サービスに送信することがあります。これらのサービスは、アプリケーションの強化とサービス提供の最適化に役立ちます。</font></font></li></ul></div><br><p><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">サービスプロバイダーは、重要な情報、必要な通知、マーケティングプロモーションを提供するために、お客様から提供された情報を随時使用することがあります。</font></font></p><br><p><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">より良い体験を提供するために、アプリケーションの使用中に、サービスプロバイダーは、特定の個人を特定できる情報（ユーザー名、住所、場所、写真など、収集したその他の情報をすべてここに追加します）の提供を要求する場合があります。サービスプロバイダーが要求する情報は、サービスプロバイダーによって保持され、このプライバシーポリシーに記載されているように使用されます。</font></font></p><br><strong><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">サードパーティのアクセス</font></font></strong><p><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">サービス プロバイダーがアプリケーションとそのサービスを改善するために、集計され匿名化されたデータのみが定期的に外部サービスに送信されます。サービス プロバイダーは、このプライバシー ポリシーに記載されている方法で、お客様の情報を第三者と共有する場合があります。</font></font></p><div><br><p><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">アプリケーションは、データの取り扱いについて独自のプライバシーポリシーを持つサードパーティのサービスを利用していることにご注意ください。以下は、アプリケーションが使用するサードパーティのサービスプロバイダーのプライバシーポリシーへのリンクです。</font></font></p><ul><!----><li><a href="https://support.google.com/admob/answer/6128543?hl=en" target="_blank" rel="noopener noreferrer"><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">アドモブ</font></font></a></li><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----><!----></ul></div><br><p><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">サービスプロバイダーは、ユーザー提供情報および自動収集情報を開示する場合があります。</font></font></p><ul><li><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">召喚状や類似の法的手続きに従うなど、法律で義務付けられている場合;</font></font></li><li><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">権利を保護するため、お客様または他者の安全を保護するため、詐欺を調査するため、または政府の要請に応じるために開示が必要であると誠実に判断した場合。</font></font></li><li><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">お客様に代わって業務を行う信頼できるサービス プロバイダーと共有し、当社が開示する情報を独自に使用することはなく、本プライバシー ポリシーに定められた規則を遵守することに同意します。</font></font></li></ul><p></p><br><strong><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">オプトアウト権</font></font></strong><p><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">アプリケーションをアンインストールすることで、アプリケーションによるすべての情報収集を簡単に停止できます。モバイル デバイスの一部として、またはモバイル アプリケーション マーケットプレイスやネットワーク経由で利用できる標準的なアンインストール プロセスを使用できます。</font></font></p><br><strong><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">データ保持ポリシー</font></font></strong><p><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">サービスプロバイダーは、お客様がアプリケーションを使用している間、およびその後も妥当な期間、ユーザー提供データを保持します。アプリケーションを通じて提供したユーザー提供データを削除したい場合は、finageapp1212@gmail.com までご連絡ください。妥当な時間内に対応いたします。</font></font></p><br><strong><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">子供たち</font></font></strong><p><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">サービスプロバイダーは、13 歳未満の子供から故意にデータを収集したり、13 歳未満の子供にマーケティングを行うためにアプリケーションを使用することはありません。</font></font></p><div><br><p><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">このアプリケーションは 13 歳未満の方を対象としていません。サービス プロバイダーは、13 歳未満のお子様から故意に個人を特定できる情報を収集することはありません。サービス プロバイダーは、13 歳未満のお子様が個人情報を提供したことが判明した場合、直ちにその情報をサーバーから削除します。親または保護者の方で、お子様が当社に個人情報を提供したことをご存知の場合は、サービス プロバイダー (finageapp1212@gmail.com) に連絡して、必要な措置を講じてください。</font></font></p></div><!----><br><strong><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">安全</font></font></strong><p><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">サービス プロバイダーは、お客様の情報の機密性を保護することに配慮しています。サービス プロバイダーは、サービス プロバイダーが処理および維持する情報を保護するために、物理的、電子的、および手続き的な保護手段を提供します。</font></font></p><br><strong><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">変更点</font></font></strong><p><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">このプライバシー ポリシーは、理由を問わず随時更新されることがあります。サービス プロバイダーは、このページを新しいプライバシー ポリシーで更新することにより、プライバシー ポリシーの変更をお客様に通知します。引き続きご利用いただくことですべての変更を承認したものとみなされるため、変更についてはこのプライバシー ポリシーを定期的に確認することをお勧めします。</font></font></p><br><p><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">このプライバシーポリシーは2024年10月23日より有効です</font></font></p><br><strong><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">あなたの同意</font></font></strong><p><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">本アプリケーションを使用することにより、お客様は、本プライバシーポリシーに現在定められている内容、および当社によって修正された内容に従って、お客様の情報を処理することに同意するものとします。</font></font></p><br><strong><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">お問い合わせ</font></font></strong><p><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">アプリケーションの使用中にプライバシーに関して質問がある場合、またはプライバシーの慣行について質問がある場合は、電子メール（finageapp1212@gmail.com）でサービスプロバイダーにお問い合わせください。</font></font></p><hr><p><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">このプライバシーポリシーページは、</font></font><a href="https://app-privacy-policy-generator.nisrulz.com/" target="_blank" rel="noopener noreferrer"><font style="vertical-align: inherit;"><font style="vertical-align: inherit;">App Privacy Policy Generatorによって生成されました。</font></font></a></p>
            </body>
            </html>
              

        """

        WebView(html: privacyPolicyHTML)
            .navigationTitle("プライバシーポリシー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(share.themeColor, for: .navigationBar)  // テーマカラーに基づいてNavigationBarの色を変更
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct WebView: UIViewRepresentable {
    let html: String?

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let html = html {
            uiView.loadHTMLString(html, baseURL: nil)
        }
    }
}
