// Argument policy for the read-only git_read and gh_read tools (review-readonly.ts).
// Each check returns null when the arguments are allowed, or the reason they are refused.
// Commands run without a shell, so only the arguments themselves can cause a write.

const GIT_SUBCOMMANDS = new Set([
  "diff", "log", "show", "status", "rev-parse", "rev-list", "merge-base",
  "ls-files", "ls-tree", "cat-file", "blame", "shortlog", "describe",
]);

// Long options that write files or run configured programs. git accepts unambiguous
// abbreviations (--outp=x means --output=x), so any prefix of these is refused too.
const GIT_BLOCKED_LONG = ["--output", "--ext-diff", "--textconv", "--open-files-in-pager", "--exec"];

export function checkGitArgs(args: string[]): string | null {
  const [sub, ...rest] = args;
  if (!sub || !GIT_SUBCOMMANDS.has(sub)) {
    return `git subcommand must be one of: ${[...GIT_SUBCOMMANDS].join(", ")}`;
  }
  for (const arg of rest) {
    if (arg === "--") break;
    if (!arg.startsWith("--")) continue;
    const name = arg.split("=")[0];
    if (name.length > 2 && GIT_BLOCKED_LONG.some((blocked) => blocked.startsWith(name))) {
      return `git option ${name} is not allowed (it can write files or run programs)`;
    }
  }
  return null;
}

const GH_COMMANDS: Record<string, Set<string>> = {
  issue: new Set(["view", "list"]),
  pr: new Set(["view", "diff", "list", "checks"]),
  run: new Set(["view", "list"]),
};

// gh api sends a POST as soon as a field or input is given, whatever the method.
const GH_API_BODY_FLAGS = ["-f", "-F", "--field", "--raw-field", "--input"];

export function checkGhArgs(args: string[]): string | null {
  const [cmd, sub] = args;
  if (args.some((a) => a === "-w" || a === "--web")) return "gh --web is not allowed";
  if (cmd === "api") return checkGhApi(args.slice(1));
  if (!cmd || !GH_COMMANDS[cmd]?.has(sub ?? "")) {
    const allowed = Object.entries(GH_COMMANDS).flatMap(([c, subs]) => [...subs].map((s) => `${c} ${s}`));
    return `gh command must be one of: ${[...allowed, "api (GET only)"].join(", ")}`;
  }
  return null;
}

function checkGhApi(args: string[]): string | null {
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    const name = arg.startsWith("--") ? arg.split("=")[0] : arg.slice(0, 2);
    if (GH_API_BODY_FLAGS.includes(name)) {
      return `gh api ${name} is not allowed (it turns the request into a POST)`;
    }
    if (name === "-X" || name === "--method") {
      const value = arg.startsWith("--") && arg.includes("=") ? arg.split("=")[1]
        : name === "-X" && arg.length > 2 ? arg.slice(2)
        : args[i + 1];
      if ((value ?? "").toUpperCase() !== "GET") return "gh api only allows the GET method";
    }
  }
  if (!args.some((a) => !a.startsWith("-"))) return "gh api needs an endpoint";
  if (args.includes("graphql")) return "gh api graphql is not allowed (it needs -f, which sends a POST)";
  return null;
}
