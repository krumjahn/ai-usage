import { readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
const config = JSON.parse(
  readFileSync(new URL("./wrangler.jsonc", import.meta.url), "utf8"),
);
if (
  config.d1_databases.some(
    (db) => db.database_id === "00000000-0000-0000-0000-000000000000",
  )
) {
  console.error(
    "Deployment is not configured. Follow docs/DEPLOYMENT.md to sign in and create the private D1 database.",
  );
  process.exit(1);
}
process.exit(
  spawnSync("npx", ["wrangler", "deploy"], { stdio: "inherit" }).status ?? 1,
);
