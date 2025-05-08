import SwiftUI
import SafariServices

struct SettingsView: View {
    @State private var showPrivacySafari = false
    @State private var showTermsSafari = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text("Настройки")
                    .font(.system(size: 30, weight: .bold, design: .default))
                    .foregroundColor(Color("primary"))
                Spacer()
            }.padding(.bottom)
            VStack(alignment: .leading, spacing: 10) {
                Text("Оставить отзыв")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(Color("primary"))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let url = URL(string: "https://t.me/Amankul") {
                            UIApplication.shared.open(url)
                        }
                    }
                Divider().background(Color.tertiary)
                Text("Поделиться приложением")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(Color("primary"))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let url = URL(string: "https://apps.apple.com/app/idYOUR_APPLE_ID") {
                            UIApplication.shared.open(url)
                        }
                    }
            }
            .padding()
            .background(Color("tertiary"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 10) {
                Text("Политика конфиденциальности")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(Color("primary"))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showPrivacySafari = true
                    }
                Divider().background(Color.tertiary)
                Text("Условия использования")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(Color("primary"))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showTermsSafari = true
                    }
            }
            .padding()
            .background(Color("tertiary"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            Spacer()
        }
        .sheet(isPresented: $showPrivacySafari) {
            if let url = URL(string: "https://yerkeamankul.github.io/chicai.privacy_policy_terms_use/privacy.html") {
                SafariView(url: url)
            }
        }
        .sheet(isPresented: $showTermsSafari) {
            if let url = URL(string: "https://yerkeamankul.github.io/chicai.privacy_policy_terms_use/terms.html") {
                SafariView(url: url)
            }
        }
        .padding()
        .background(Color.white)
    }

}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
