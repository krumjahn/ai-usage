import SwiftUI

struct FeedbackView: View {
    @ObservedObject var model: FeedbackModel
    @State private var sendTask: Task<Void, Never>?
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(model.submitted ? "Thank you." : "Help shape AI Usage")
                .font(.title2.weight(.semibold))
            if model.submitted {
                Text("Your answers will help decide what comes next.").foregroundStyle(.secondary)
                Button("Done") { model.isPresented = false }.keyboardShortcut(.defaultAction)
            } else if !model.isConfigured {
                Text("Online feedback is not connected in this build. You can share an idea on GitHub instead.")
                    .foregroundStyle(.secondary)
                Link("Share an idea on GitHub", destination: URL(string: "https://github.com/krumjahn/ai-usage/issues/new/choose")!)
                Button("Done") { model.isPresented = false }
            } else {
                Text("Three quick questions. Completely optional.").foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 6) {
                    Text("What brought you here?").font(.callout.weight(.medium))
                    Picker("What brought you here?", selection: $model.reason) {
                        Text("Choose a reason").tag(Optional<FeedbackReason>.none)
                        ForEach(FeedbackReason.allCases, id: \.self) { Text($0.label).tag(Optional($0)) }
                    }.labelsHidden().disabled(model.sending)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("What do you mainly use AI for?").font(.callout.weight(.medium))
                    Picker("What do you mainly use AI for?", selection: $model.useCase) {
                        Text("Choose a use").tag(Optional<FeedbackUseCase>.none)
                        ForEach(FeedbackUseCase.allCases, id: \.self) { Text($0.label).tag(Optional($0)) }
                    }.labelsHidden().disabled(model.sending)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("What would make this more useful?").font(.callout.weight(.medium))
                    TextEditor(text: $model.wish).font(.callout).frame(height: 65)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(.secondary.opacity(0.25)))
                        .accessibilityLabel("Optional feature request").disabled(model.sending)
                    Text("Optional · \(model.wish.unicodeScalars.count)/500 characters")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Text("Send only these answers and the app version to the project's Cloudflare service. No activity history or email. Avoid personal or confidential details. Responses are kept for 90 days.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                if let problem = model.problem { Text(problem).font(.caption).foregroundStyle(.red) }
                HStack {
                    Button("Skip") { sendTask?.cancel(); model.isPresented = false }.keyboardShortcut(.cancelAction)
                    Spacer()
                    if model.sending { ProgressView().controlSize(.small) }
                    Button(model.sending ? "Sending…" : "Send feedback") {
                        sendTask = Task { await model.submit() }
                    }.disabled(!model.canSubmit).keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(22).frame(width: 380)
        .onDisappear { sendTask?.cancel() }
    }
}

struct FeedbackPresentation: ViewModifier {
    @ObservedObject var model: FeedbackModel
    func body(content: Content) -> some View {
        content.sheet(isPresented: $model.isPresented) { FeedbackView(model: model) }
            .onAppear { model.presentIfNeeded() }
    }
}
