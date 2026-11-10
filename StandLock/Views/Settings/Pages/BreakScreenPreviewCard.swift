import SwiftUI

struct BreakScreenPreviewCard: View {
    let look: BreakScreenLook

    var body: some View {
        RestRecallContent(remainingSeconds: 300, palette: look.palette)
            .frame(maxWidth: .infinity, minHeight: 190)
            .clipShape(RoundedRectangle(cornerRadius: SettingsTokens.previewRadius))
            .environment(\.colorScheme, look.colorScheme)
    }
}
