// node --test ~/.pi/agent/subagent-tools/review-readonly-policy.test.ts
import { test } from "node:test";
import assert from "node:assert/strict";
import { checkGitArgs, checkGhArgs } from "./review-readonly-policy.ts";

const allowed = (reason: string | null) => assert.equal(reason, null);
const refused = (reason: string | null) => assert.notEqual(reason, null);

test("git: read commands a review needs are allowed", () => {
  allowed(checkGitArgs(["diff", "origin/main...HEAD"]));
  allowed(checkGitArgs(["diff", "--stat", "origin/main...HEAD", "--", "README.md"]));
  allowed(checkGitArgs(["log", "--oneline", "origin/main..HEAD"]));
  allowed(checkGitArgs(["show", "HEAD:README.md"]));
  allowed(checkGitArgs(["status", "--short"]));
  allowed(checkGitArgs(["diff", "--output-indicator-new=+", "--", "--output"])); // after --: a path
});

test("git: commands that change the repository are refused", () => {
  for (const sub of ["commit", "push", "checkout", "reset", "branch", "tag", "config", "stash", "apply", "-c", "--git-dir=/x"]) {
    refused(checkGitArgs([sub]));
  }
  refused(checkGitArgs([]));
});

test("git: options that write files or run programs are refused, abbreviated too", () => {
  refused(checkGitArgs(["diff", "--output=/tmp/x"]));
  refused(checkGitArgs(["log", "--output", "/tmp/x"]));
  refused(checkGitArgs(["diff", "--outp=/tmp/x"]));
  refused(checkGitArgs(["diff", "--ext-diff"]));
  refused(checkGitArgs(["diff", "--ext"]));
  refused(checkGitArgs(["show", "--textconv"]));
});

test("gh: reads a review needs are allowed", () => {
  allowed(checkGhArgs(["issue", "view", "27", "-R", "ovotech/ciam-microcks", "--comments"]));
  allowed(checkGhArgs(["pr", "diff", "41"]));
  allowed(checkGhArgs(["api", "repos/ovotech/ciam-microcks/issues/27/comments"]));
  allowed(checkGhArgs(["api", "-X", "GET", "repos/o/r/pulls"]));
  allowed(checkGhArgs(["api", "--method=get", "repos/o/r/pulls", "--jq", ".[].title"]));
});

test("gh: commands that change anything are refused", () => {
  refused(checkGhArgs(["issue", "comment", "27", "--body", "x"]));
  refused(checkGhArgs(["issue", "close", "27"]));
  refused(checkGhArgs(["pr", "merge", "41"]));
  refused(checkGhArgs(["pr", "review", "41", "--approve"]));
  refused(checkGhArgs(["repo", "delete"]));
  refused(checkGhArgs(["secret", "list"]));
  refused(checkGhArgs(["issue", "view", "27", "--web"]));
  refused(checkGhArgs([]));
});

test("gh api: anything but a plain GET is refused", () => {
  refused(checkGhArgs(["api", "-X", "POST", "repos/o/r/issues"]));
  refused(checkGhArgs(["api", "-XDELETE", "repos/o/r"]));
  refused(checkGhArgs(["api", "--method", "PATCH", "repos/o/r"]));
  refused(checkGhArgs(["api", "repos/o/r/issues", "-f", "title=x"]));
  refused(checkGhArgs(["api", "repos/o/r/issues", "-Ftitle=x"]));
  refused(checkGhArgs(["api", "repos/o/r/issues", "--raw-field", "title=x"]));
  refused(checkGhArgs(["api", "repos/o/r/issues", "--input", "body.json"]));
  refused(checkGhArgs(["api", "graphql"]));
  refused(checkGhArgs(["api"]));
});
