import Foundation

// Brainrot's two browser scripting dictionaries. The helper receives only a
// fixed script. A URL exists briefly in memory and only a registry host escapes.
enum BrowserAdapter {
    static let supported = ["com.apple.Safari", "com.google.Chrome", "company.thebrowser.Browser",
                            "com.microsoft.edgemac", "com.brave.Browser"]
    enum Result { case allowed(String?), denied, unavailable }

    static func fetch(_ id: String) -> Result {
        guard supported.contains(id) else { return .unavailable }
        let property = id == "com.apple.Safari" ? "URL of front document" : "URL of active tab of front window"
        let script = """
            try
                with timeout of 3 seconds
                    tell application id "\(id)" to return \(property)
                end timeout
            on error errorText number errorNumber
                return "error:" & errorNumber
            end try
            """
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return .unavailable }
        let bytes = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let value = String(decoding: bytes, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        if value == "error:-1743" { return .denied }
        guard process.terminationStatus == 0, !value.hasPrefix("error:"), !value.isEmpty else { return .unavailable }
        return .allowed(AIToolClassifier.domain(from: value))
    }
}
