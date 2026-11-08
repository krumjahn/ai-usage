import Foundation
import SQLite3

struct LedgerError: LocalizedError {
    var message: String
    var errorDescription: String? { message }
    init(_ message: String) { self.message = message }
}

// Single owner, parameter-bound SQLite writer adapted from Brainrot's UsageStore.
final class ActivityStore {
    static let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("com.rumjahn.attentionledger", isDirectory: true)
    private var db: OpaquePointer?
    private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    init(url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
            let error = failure()
            sqlite3_close(db)
            throw error
        }
        do {
            sqlite3_busy_timeout(db, 250)
            try execute("PRAGMA journal_mode=WAL")
            try execute("PRAGMA synchronous=FULL")
            try execute("PRAGMA secure_delete=ON")
            let version = try statement("PRAGMA user_version")
            let current = sqlite3_step(version) == SQLITE_ROW ? sqlite3_column_int(version, 0) : -1
            sqlite3_finalize(version)
            switch current {
            case 0:
                try execute("""
                    BEGIN IMMEDIATE;
                    CREATE TABLE segments (start REAL PRIMARY KEY, end REAL NOT NULL CHECK(end>start),
                      app TEXT NOT NULL, bundle TEXT NOT NULL, domain TEXT);
                    PRAGMA user_version=1;
                    COMMIT;
                    """)
            case 1, 2: break
            default: throw LedgerError("Unsupported database version \(current)")
            }
            if current < 2 {
                // Legacy observations remain readable. Their original rule version is unknown.
                try execute("""
                    BEGIN IMMEDIATE;
                    ALTER TABLE segments ADD COLUMN rule_version INTEGER;
                    ALTER TABLE segments ADD COLUMN matched_tool TEXT;
                    ALTER TABLE segments ADD COLUMN evidence TEXT;
                    CREATE INDEX segments_end ON segments(end);
                    PRAGMA user_version=2;
                    COMMIT;
                    """)
            }
        } catch {
            sqlite3_close(db)
            db = nil
            throw error
        }
    }
    deinit { sqlite3_close(db) }

    private func failure() -> LedgerError { LedgerError(String(cString: sqlite3_errmsg(db))) }
    private func execute(_ sql: String) throws {
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else { throw failure() }
    }
    private func statement(_ sql: String) throws -> OpaquePointer {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { throw failure() }
        return stmt
    }

    func append(_ batch: [Segment]) throws {
        guard !batch.isEmpty else { return }
        try execute("BEGIN IMMEDIATE")
        do {
            let insert = try statement("INSERT INTO segments VALUES (?,?,?,?,?,?,?,?)")
            defer { sqlite3_finalize(insert) }
            let merge = try statement("""
                UPDATE segments SET end=? WHERE start=(SELECT max(start) FROM segments)
                AND end=? AND app=? AND bundle=? AND domain IS ? AND rule_version=?
                """)
            defer { sqlite3_finalize(merge) }
            for s in batch where s.end > s.start {
                for stmt in [merge, insert] {
                    sqlite3_reset(stmt)
                    sqlite3_bind_double(stmt, 1, stmt == merge ? s.end : s.start)
                    sqlite3_bind_double(stmt, 2, stmt == merge ? s.start : s.end)
                    sqlite3_bind_text(stmt, 3, s.observation.app, -1, transient)
                    sqlite3_bind_text(stmt, 4, s.observation.bundle, -1, transient)
                    sqlite3_bind_text(stmt, 5, s.observation.domain, -1, transient)
                    let match = AIToolClassifier.classify(s.observation)
                    sqlite3_bind_int(stmt, 6, Int32(match.version))
                    if stmt == insert {
                        sqlite3_bind_text(stmt, 7, match.tool, -1, transient)
                        sqlite3_bind_text(stmt, 8, match.evidence, -1, transient)
                    }
                    guard sqlite3_step(stmt) == SQLITE_DONE else { throw failure() }
                    if sqlite3_changes(db) == 1 { break }
                }
            }
            try execute("COMMIT")
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }
    func read(since: Double = 0) throws -> [Segment] {
        let stmt = try statement("SELECT start,end,app,bundle,domain,rule_version,matched_tool,evidence FROM segments WHERE end>? ORDER BY start")
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_double(stmt, 1, since)
        var result = [Segment]()
        while true {
            switch sqlite3_step(stmt) {
            case SQLITE_DONE: return result
            case SQLITE_ROW:
                func text(_ i: Int32) -> String? { sqlite3_column_text(stmt, i).map { String(cString: $0) } }
                result.append(Segment(start: sqlite3_column_double(stmt, 0), end: sqlite3_column_double(stmt, 1),
                    observation: Observation(app: text(2) ?? "", bundle: text(3) ?? "", domain: text(4)),
                    recordedClassification: text(7).map { AIToolClassifier.Match(tool: text(6), evidence: $0, version: Int(sqlite3_column_int(stmt, 5))) }))
            default: throw failure()
            }
        }
    }
    func erase() throws {
        try execute("DELETE FROM segments")
        try execute("PRAGMA wal_checkpoint(TRUNCATE)")
    }
}
