import SwiftUI
import StandLockCore

struct ManuscriptBreakView: View {
    let look: BreakScreenLook
    @State private var remainingSeconds: TimeInterval

    init(look: BreakScreenLook, totalDuration: TimeInterval) {
        self.look = look
        _remainingSeconds = State(initialValue: totalDuration)
    }

    var body: some View {
        RestRecallContent(remainingSeconds: remainingSeconds, palette: look.palette)
            .ignoresSafeArea()
            .preferredColorScheme(look.colorScheme)
            .task {
                let end = Date().addingTimeInterval(remainingSeconds)
                while remainingSeconds > 0 {
                    do { try await Task.sleep(for: .seconds(1)) }
                    catch { return }
                    remainingSeconds = breakSecondsRemaining(until: end)
                }
            }
    }
}
