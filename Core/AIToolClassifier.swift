import Foundation

// Registry keys are product surfaces. Unknown browsing discards the host.
struct AIToolClassifier {
    static let version = 6
    static let domains = [
        "chatgpt.com": "ChatGPT", "chat.openai.com": "ChatGPT",
        "claude.ai": "Claude", "gemini.google.com": "Gemini", "grok.com": "Grok",
        "perplexity.ai": "Perplexity", "copilot.microsoft.com": "Microsoft Copilot",
        "notebooklm.google.com": "NotebookLM", "aistudio.google.com": "Google AI Studio",
        "chat.deepseek.com": "DeepSeek", "v0.app": "v0",
        "agent.minimax.io": "MiniMax Code"
    ]
    static let bundles = [
        "com.openai.chat": "ChatGPT", "com.openai.codex": "Codex",
        "com.anthropic.claudefordesktop": "Claude", "com.todesktop.230313mzl4w4u92": "Cursor",
        "com.exafunction.windsurf": "Windsurf", "com.minimax.agent": "MiniMax Code"
    ]

    struct DesktopIdentity {
        let bundle: String
        let name: String
        let tool: String
    }

    // Match both fields for installed apps that share or retain another product's
    // bundle ID. Attribution describes the foreground app, including its embedded surfaces.
    static let desktopIdentities = [
        DesktopIdentity(bundle: "com.openai.codex", name: "ChatGPT", tool: "ChatGPT"),
        DesktopIdentity(bundle: "com.anysphere.sand", name: "Grok Bot", tool: "Grok Bot")
    ]

    // Separate product identities even when a product has no observable signal.
    // Claude Code inside a terminal cannot be identified by this collector.
    static let products = Set(domains.values).union(bundles.values).union(desktopIdentities.map(\.tool)).union(["Claude Code"])

    static func domain(from address: String?) -> String? {
        guard let address, let parts = URLComponents(string: address),
              ["https", "http"].contains(parts.scheme?.lowercased() ?? ""),
              var host = parts.host?.lowercased() else { return nil }
        if host.hasSuffix(".") { host.removeLast() }
        return domains.keys.first { host == $0 || host.hasSuffix("." + $0) }
    }

    struct Match: Codable, Equatable {
        let tool: String?
        let evidence: String
        var version: Int = AIToolClassifier.version
    }
    static func classify(_ app: Observation) -> Match {
        if BrowserAdapter.supported.contains(app.bundle), let domain = app.domain, let tool = domains[domain] {
            return Match(tool: tool, evidence: "domain:" + domain)
        }
        if let identity = desktopIdentities.first(where: {
            $0.bundle == app.bundle.lowercased() && $0.name.lowercased() == app.app.lowercased()
        }) {
            return Match(tool: identity.tool, evidence: "bundle:" + app.bundle + ";app:" + app.app)
        }
        if let tool = bundles[app.bundle.lowercased()] {
            return Match(tool: tool, evidence: "bundle:" + app.bundle)
        }
        return Match(tool: nil, evidence: "unmatched")
    }
}
