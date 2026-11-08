/// <reference path="../worker-configuration.d.ts" />

const reasons = new Set(["understand", "compare", "focus", "curious", "other"]);
const uses = new Set(["coding", "research", "writing", "design", "other"]);
const fields = new Set([
  "id",
  "schemaVersion",
  "reason",
  "useCase",
  "wish",
  "appVersion",
]);

/** @param {unknown} body */
export function validateFeedback(body) {
  if (!body || typeof body !== "object" || Array.isArray(body)) return null;
  const v = /** @type {Record<string, unknown>} */ (body);
  if (Object.keys(v).some((key) => !fields.has(key))) return null;
  if (
    typeof v.id !== "string" ||
    !/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
      v.id,
    )
  )
    return null;
  if (
    v.schemaVersion !== 1 ||
    typeof v.reason !== "string" ||
    !reasons.has(v.reason) ||
    typeof v.useCase !== "string" ||
    !uses.has(v.useCase)
  )
    return null;
  if (
    typeof v.wish !== "string" ||
    [...v.wish].length > 500 ||
    /[\u0000-\u0008\u000b\u000c\u000e-\u001f]/.test(v.wish)
  )
    return null;
  if (typeof v.appVersion !== "string" || !/^[\w.+-]{1,32}$/.test(v.appVersion))
    return null;
  return {
    id: v.id.toLowerCase(),
    reason: v.reason,
    useCase: v.useCase,
    wish: v.wish.trim(),
    appVersion: v.appVersion,
    schemaVersion: 1,
  };
}

/** @param {object} value @param {number} status */
function json(value, status = 200) {
  return Response.json(value, {
    status,
    headers: {
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
    },
  });
}

/** @param {Request} request */
async function limitedJSON(request) {
  const reader = request.body?.getReader();
  if (!reader) throw new Error("empty");
  let total = 0;
  const chunks = [];
  try {
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      total += value.byteLength;
      if (total > 4096) {
        await reader.cancel();
        throw new Error("large");
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }
  const bytes = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return JSON.parse(
    new TextDecoder("utf-8", { fatal: true, ignoreBOM: false }).decode(bytes),
  );
}

/** @satisfies {ExportedHandler<Env>} */
export default {
  /** @param {Request} request @param {Env} env */
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === "/api/health" && request.method === "GET")
      return json({ ok: true });
    if (url.pathname !== "/api/feedback") {
      return url.pathname.startsWith("/api/")
        ? json({ error: "Not found" }, 404)
        : env.ASSETS.fetch(request);
    }
    // No public read/export endpoint. Native requests have no Origin.
    if (request.method !== "POST")
      return json({ error: "Method not allowed" }, 405);
    const origin = request.headers.get("Origin");
    if (origin && origin !== url.origin)
      return json({ error: "Origin not allowed" }, 403);
    if (
      request.headers.get("Content-Type")?.split(";")[0].trim() !==
      "application/json"
    )
      return json({ error: "JSON required" }, 415);
    if (Number(request.headers.get("Content-Length")) > 4096)
      return json({ error: "Request too large" }, 413);
    // IP is used transiently for abuse control; it is never written to the response database.
    const source = request.headers.get("CF-Connecting-IP") || "local";
    const hour = Math.floor(Date.now() / 3_600_000);
    const digest = await crypto.subtle.digest(
      "SHA-256",
      new TextEncoder().encode(`feedback:${hour}:${source}`),
    );
    const key = Array.from(new Uint8Array(digest), (b) =>
      b.toString(16).padStart(2, "0"),
    ).join("");
    const { success } = await env.FEEDBACK_LIMITER.limit({ key });
    if (!success)
      return new Response(
        JSON.stringify({ error: "Please try again shortly" }),
        {
          status: 429,
          headers: {
            "Content-Type": "application/json",
            "Cache-Control": "no-store",
            "Retry-After": "60",
          },
        },
      );
    let body;
    try {
      body = await limitedJSON(request);
    } catch (error) {
      return json(
        { error: "Invalid request" },
        error instanceof Error && error.message === "large" ? 413 : 400,
      );
    }
    const data = validateFeedback(body);
    if (!data) return json({ error: "Invalid answers" }, 400);
    try {
      // One random ID per submission makes retries safe without a persistent user identifier.
      await env.FEEDBACK_DB.prepare(
        "INSERT OR IGNORE INTO feedback (id, reason, use_case, wish, app_version, schema_version) VALUES (?, ?, ?, ?, ?, ?)",
      )
        .bind(
          data.id,
          data.reason,
          data.useCase,
          data.wish,
          data.appVersion,
          data.schemaVersion,
        )
        .run();
      return json({ ok: true, id: data.id }, 201);
    } catch {
      return json({ error: "Could not save. Please try again later." }, 503);
    }
  },
  /** @param {ScheduledController} _event @param {Env} env */
  async scheduled(_event, env) {
    await env.FEEDBACK_DB.prepare(
      "DELETE FROM feedback WHERE created_at < strftime('%Y-%m-%dT%H:%M:%SZ', 'now', '-90 days')",
    ).run();
  },
};
