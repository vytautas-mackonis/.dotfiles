// Read-only git and gh tools for the pi-subagents `reviewer` agent, which has no shell.
// Loaded only in reviewer child sessions, through a path entry in
// subagents.agentOverrides.reviewer.tools (~/.pi/agent/settings.json); never auto-discovered.
// Commands run without a shell; review-readonly-policy.ts decides which arguments are allowed.

import { execFile } from "node:child_process";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { checkGhArgs, checkGitArgs } from "./review-readonly-policy.ts";

const MAX_LINES = 2000;
const MAX_BYTES = 50 * 1024;

const ENV = {
  ...process.env,
  GIT_PAGER: "cat",
  GIT_OPTIONAL_LOCKS: "0",
  GIT_TERMINAL_PROMPT: "0",
  GH_PAGER: "cat",
  GH_PROMPT_DISABLED: "1",
  NO_COLOR: "1",
};

function run(cmd: string, args: string[], cwd: string, signal?: AbortSignal): Promise<string> {
  return new Promise((resolve, reject) => {
    execFile(cmd, args, { cwd, env: ENV, signal, timeout: 120_000, maxBuffer: 256 * 1024 * 1024 },
      (error, stdout, stderr) => {
        if (error) reject(new Error(`${cmd} ${args.join(" ")} failed: ${stderr.trim() || error.message}`));
        else resolve(stdout);
      });
  });
}

// Keeps the first MAX_LINES lines / MAX_BYTES bytes; the full output goes to a temp file for `read`.
function truncate(output: string, tool: string): string {
  const lines = output.split("\n");
  let kept = lines.slice(0, MAX_LINES).join("\n");
  if (Buffer.byteLength(kept) > MAX_BYTES) kept = Buffer.from(kept).subarray(0, MAX_BYTES).toString();
  if (kept.length === output.length) return output || "(no output)";
  const file = join(mkdtempSync(join(tmpdir(), `pi-${tool}-`)), "output.txt");
  writeFileSync(file, output);
  return `${kept}\n\n[Truncated: ${lines.length} lines in total. Full output: ${file}; use read with offset/limit.]`;
}

const Args = Type.Object({
  args: Type.Array(Type.String(), { description: "Arguments after the command name, one per element" }),
});

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "git_read",
    label: "git (read-only)",
    description:
      "Run a read-only git command in the working directory: diff, log, show, status, rev-parse, rev-list, " +
      "merge-base, ls-files, ls-tree, cat-file, blame, shortlog or describe. Use it for committed ranges, e.g. " +
      'args ["diff", "origin/main...HEAD"] or ["log", "--oneline", "origin/main..HEAD"]. ' +
      `Output over ${MAX_LINES} lines or ${MAX_BYTES / 1024} KB is truncated and saved to a file.`,
    parameters: Args,
    async execute(_id, params, signal, _onUpdate, ctx) {
      const refusal = checkGitArgs(params.args);
      if (refusal) throw new Error(refusal);
      const [sub, ...rest] = params.args;
      const out = await run("git", ["--no-pager", "-c", "core.fsmonitor=false", sub, ...rest], ctx.cwd, signal);
      return { content: [{ type: "text", text: truncate(out, "git") }], details: { args: params.args } };
    },
  });

  pi.registerTool({
    name: "gh_read",
    label: "gh (read-only)",
    description:
      "Run a read-only GitHub CLI command: issue view/list, pr view/diff/list/checks, run view/list, or api " +
      '(GET only, no fields). E.g. args ["issue", "view", "27", "-R", "owner/repo", "--comments"]. ' +
      `Output over ${MAX_LINES} lines or ${MAX_BYTES / 1024} KB is truncated and saved to a file.`,
    parameters: Args,
    async execute(_id, params, signal, _onUpdate, ctx) {
      const refusal = checkGhArgs(params.args);
      if (refusal) throw new Error(refusal);
      const out = await run("gh", params.args, ctx.cwd, signal);
      return { content: [{ type: "text", text: truncate(out, "gh") }], details: { args: params.args } };
    },
  });
}
