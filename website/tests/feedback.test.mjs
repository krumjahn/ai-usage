import test from "node:test";
import assert from "node:assert/strict";
import worker, { validateFeedback } from "../src/index.js";
const answer = {
  id: "12345678-1234-4123-8123-123456789abc",
  schemaVersion: 1,
  reason: "understand",
  useCase: "coding",
  wish: "Weekly trends",
  appVersion: "0.1.0",
};
function fixture({ success = true, fail = false } = {}) {
  const writes = [];
  const env = {
    FEEDBACK_LIMITER: { limit: async () => ({ success }) },
    FEEDBACK_DB: {
      prepare(sql) {
        return {
          bind(...values) {
            return {
              async run() {
                if (fail) throw Error("db");
                writes.push({ sql, values });
              },
            };
          },
          async run() {
            writes.push({ sql });
          },
        };
      },
    },
  };
  return { env, writes };
}
function request(body = answer, options = {}) {
  return new Request("https://example.com/api/feedback", {
    method: "POST",
    headers: { "Content-Type": "application/json", ...options.headers },
    body: typeof body === "string" ? body : JSON.stringify(body),
  });
}
test("allowlist excludes identity and activity; checks Unicode limit and enums", () => {
  assert.deepEqual(validateFeedback(answer), answer);
  for (const body of [
    null,
    [],
    { ...answer, email: "x" },
    { ...answer, history: [] },
    { ...answer, reason: "bad" },
    { ...answer, schemaVersion: 2 },
    { ...answer, id: "not-uuid" },
    { ...answer, wish: "🧠".repeat(501) },
    { ...answer, wish: "\0" },
  ])
    assert.equal(validateFeedback(body), null);
  assert.ok(validateFeedback({ ...answer, wish: "🧠".repeat(500) }));
});
test("explicit JSON submission uses bound values and returns matching receipt", async () => {
  const { env, writes } = fixture();
  const payload = { ...answer, wish: "'); DROP TABLE feedback; --" };
  const result = await worker.fetch(request(payload), env);
  assert.equal(result.status, 201);
  assert.deepEqual(await result.json(), { ok: true, id: answer.id });
  assert.equal(writes.length, 1);
  assert.equal(writes[0].values[3], payload.wish);
  assert.ok(!writes[0].sql.includes(payload.wish));
});
test("no public response read endpoint or marketing website", async () => {
  const { env } = fixture();
  assert.equal(
    (await worker.fetch(new Request("https://example.com/api/feedback"), env))
      .status,
    405,
  );
  assert.equal(
    (await worker.fetch(new Request("https://example.com/api/export"), env))
      .status,
    404,
  );
  assert.equal(
    (await worker.fetch(new Request("https://example.com/"), env)).status,
    404,
  );
});
test("rejects malformed, oversized, cross-origin and non-JSON requests before storage", async () => {
  const { env, writes } = fixture();
  for (const [req, status] of [
    [request("{"), 400],
    [request("x".repeat(4097)), 413],
    [request(answer, { headers: { Origin: "https://evil.test" } }), 403],
    [request(answer, { headers: { "Content-Type": "text/plain" } }), 415],
    [request({ ...answer, email: "x" }), 400],
  ])
    assert.equal((await worker.fetch(req, env)).status, status);
  assert.equal(writes.length, 0);
});
test("abuse limit and write failure do not report success", async () => {
  assert.equal(
    (await worker.fetch(request(), fixture({ success: false }).env)).status,
    429,
  );
  assert.equal(
    (await worker.fetch(request(), fixture({ fail: true }).env)).status,
    503,
  );
});
test("scheduled retention deletes records older than 90 days", async () => {
  const { env, writes } = fixture();
  await worker.scheduled({}, env);
  assert.match(writes[0].sql, /-90 days/);
});
