import fs from "node:fs/promises";

const universeId = "9421311218";
const placeId = "118064584465155";
const apiKey = process.env.ROBLOX_API_KEY;

if (!apiKey) {
  console.error("ROBLOX_API_KEY secret is missing.");
  process.exit(2);
}

const script = await fs.readFile(new URL("./patch.luau", import.meta.url), "utf8");

const base = "https://apis.roblox.com/cloud/v2/";
const createUrl =
  base +
  "universes/" +
  universeId +
  "/places/" +
  placeId +
  "/luau-execution-session-tasks";

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const create = await fetch(createUrl, {
  method: "POST",
  headers: {
    "x-api-key": apiKey,
    "content-type": "application/json",
  },
  body: JSON.stringify({
    timeout: "180s",
    script,
  }),
});

const createText = await create.text();
let task;
try {
  task = JSON.parse(createText);
} catch {
  throw new Error("Roblox returned non-JSON: " + createText);
}

if (!create.ok) {
  throw new Error(
    "Failed to create Luau task (" +
      create.status +
      "): " +
      JSON.stringify(task),
  );
}

for (let i = 0; i < 120; i += 1) {
  const state = String(task?.state ?? "").toUpperCase();

  if (!["PROCESSING", "QUEUED", "PENDING", ""].includes(state)) {
    break;
  }

  if (!task?.path) {
    throw new Error("Roblox task did not return an operation path.");
  }

  await sleep(1500);

  const poll = await fetch(base + task.path, {
    headers: { "x-api-key": apiKey },
  });

  const pollText = await poll.text();
  try {
    task = JSON.parse(pollText);
  } catch {
    throw new Error("Roblox poll returned non-JSON: " + pollText);
  }

  if (!poll.ok) {
    throw new Error(
      "Failed to poll Luau task (" +
        poll.status +
        "): " +
        JSON.stringify(task),
    );
  }
}

console.log(JSON.stringify(task, null, 2));

if (task?.error) {
  console.error("Roblox Luau task failed:", JSON.stringify(task.error));
  process.exit(3);
}

const state = String(task?.state ?? "").toUpperCase();
if (["FAILED", "ERROR", "CANCELLED", "CANCELED"].includes(state)) {
  process.exit(4);
}

console.log("Roblox patch completed.");
