#!/usr/bin/env python3
"""
PreToolUse guard for the Bash tool.

Deterministic enforcement of the HARD RULES in ~/.claude/CLAUDE.md. These rules must not
depend on the model deciding to follow them, so they are mechanical: exit 2 blocks the
call and returns the message to the agent.

Edit RULES below to tune. Exit 0 = allow, exit 2 = block.
"""
import json
import os
import re
import subprocess
import sys

PROTECTED = ("main", "master", "production", "release")

# Absolute prefixes the agent may recursively delete: its own session scratchpad.
SAFE_RM_PREFIXES = ("/tmp/claude-", "/private/tmp/claude-", "/var/folders/")

SAFE_RM_ROOTS = {
    "node_modules", "dist", "build", "out", "coverage", ".nx", ".turbo",
    ".cache", ".next", ".nuxt", ".output", ".aws-sam", "cdk.out",
    "tmp", "temp", ".pytest_cache", "__pycache__", ".vite",
}


def read_input():
    try:
        return json.load(sys.stdin)
    except Exception:
        return {}


def current_branch(cwd):
    try:
        r = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            cwd=cwd, capture_output=True, text=True, timeout=5,
        )
        return r.stdout.strip() if r.returncode == 0 else ""
    except Exception:
        return ""


def block(rule, why, instead):
    print(f"BLOCKED by guard-bash [{rule}]\n\n{why}\n\nInstead: {instead}", file=sys.stderr)
    sys.exit(2)


def rm_targets(cmd):
    """Targets of any `rm` invocation that uses both -r and -f."""
    out = []
    for m in re.finditer(r"(?:^|[;&|\n]|&&)\s*(?:sudo\s+)?rm\s+([^;&|\n]*)", cmd):
        args = m.group(1).split()
        flags = [a for a in args if a.startswith("-")]
        flagstr = "".join(flags)
        recursive = "r" in flagstr or "R" in flagstr or "--recursive" in flags
        force = "f" in flagstr or "--force" in flags
        if recursive and force:
            out.extend(a for a in args if not a.startswith("-"))
    return out


# A heredoc body is usually DATA (written to a file), not code. Scanning it produces false
# positives whenever the agent writes documentation about a forbidden command. Strip those
# bodies before matching -- but keep them when the heredoc feeds an interpreter, which
# would actually execute the content.
INTERP_NAMES = {
    "sh", "bash", "zsh", "ksh", "dash", "python", "python3", "node", "perl",
    "ruby", "psql", "mysql", "mariadb", "awk", "xargs", "eval", "tee",
}


def feeds_interpreter(prefix):
    """True if the text before `<<` is a command that EXECUTES the heredoc body.

    Must match on the command word only: `cat > x.sh` contains "sh" but writes a file.
    """
    seg = re.split(r"\|\||&&|[|;]", prefix)[-1]
    for tok in seg.split():
        if tok in (">", ">>", "<", "2>", "&>"):
            break
        if tok.startswith(("-", ">", "<")):
            continue
        if os.path.basename(tok) in INTERP_NAMES:
            return True
    return False


def strip_heredocs(cmd):
    lines = cmd.split("\n")
    out, i = [], 0
    while i < len(lines):
        line = lines[i]
        out.append(line)
        m = re.search(r"<<-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1", line)
        if not m:
            i += 1
            continue
        delim = m.group(2)
        executed = feeds_interpreter(line[:m.start()])
        i += 1
        body = []
        while i < len(lines) and lines[i].strip() != delim:
            body.append(lines[i])
            i += 1
        if executed:
            out.extend(body)
        i += 1  # skip the closing delimiter
    return "\n".join(out)


def main():
    data = read_input()
    cmd = (data.get("tool_input") or {}).get("command", "") or ""
    cwd = data.get("cwd") or os.getcwd()
    if not cmd.strip():
        sys.exit(0)
    # Newlines separate commands just like `;` does. Normalising them keeps every
    # rule's `[^;&|]*` from spanning lines, and makes line-leading commands visible.
    cmd = strip_heredocs(cmd).replace("\n", " ; ")

    # ---- 1. Bypassing verification --------------------------------------------------
    if re.search(r"--no-verify|--no-gpg-sign\b", cmd):
        block("no-verify",
              "This flag exists to skip the hooks that enforce the safety rules.",
              "fix what the hook is complaining about; never route around it.")

    # ---- 2. Git: protected branches --------------------------------------------------
    branch = current_branch(cwd) if "git " in cmd or cmd.strip().startswith("git") else ""

    if re.search(r"\bgit\s+push\b", cmd):
        if re.search(r"\bgit\s+push\b[^;&|]*\b(main|master|production|release)\b", cmd):
            block("push-protected",
                  "Pushing to a protected branch is forbidden without exception.",
                  "push a feature branch: git push -u origin <feature-branch>")
        if branch in PROTECTED and not re.search(r"\bgit\s+push\b[^;&|]*\s\S+\s+\S+", cmd):
            block("push-protected",
                  f"HEAD is on '{branch}'; a bare `git push` would push a protected branch.",
                  "create a feature branch first, then push it explicitly.")
        if re.search(r"\bgit\s+push\b[^;&|]*(--force\b|(?<![\w-])-f\b)", cmd) \
                and "--force-with-lease" not in cmd:
            block("force-push",
                  "A plain force-push silently discards commits pushed by someone else.",
                  "use --force-with-lease, and only on your own feature branch.")

    if re.search(r"\bgit\s+commit\b", cmd) and branch in PROTECTED:
        block("commit-protected",
              f"HEAD is on '{branch}'. Committing to a protected branch is forbidden.",
              "ask the user which branch to use, or create one: git switch -c <branch>")

    if re.search(r"\bgh\s+pr\s+create\b|\bgh\s+api\b[^;&|]*\bpulls\b", cmd):
        block("pr-create",
              "Pull requests are opened by the human, never by the agent.",
              "push the branch and show the user the Create-PR link git prints.")

    # ---- 3. Git: history / working-tree destruction ----------------------------------
    if re.search(r"\bgit\s+reset\s+[^;&|]*--hard\b", cmd):
        block("reset-hard",
              "`git reset --hard` destroys uncommitted work irreversibly.",
              "git stash, or commit to a scratch branch, and confirm with the user first.")
    if re.search(r"\bgit\s+clean\b[^;&|]*-[a-zA-Z]*[fd]", cmd):
        block("git-clean",
              "`git clean -fd` deletes untracked files, including ones never backed up.",
              "run `git clean -nd` first and show the user what would be removed.")
    if re.search(r"\bgit\s+branch\s+-[dD]\b[^;&|]*\b(main|master)\b", cmd):
        block("delete-protected", "Deleting a protected branch.", "do not.")
    if re.search(r"\bgit\s+push\b[^;&|]*--delete\b", cmd):
        block("delete-remote",
              "Deleting a remote branch is destructive and outward-facing.",
              "ask the user to delete it themselves.")

    # ---- 4. Filesystem destruction ---------------------------------------------------
    if "--no-preserve-root" in cmd:
        block("rm-root", "`--no-preserve-root` has exactly one purpose.", "no.")
    for t in rm_targets(cmd):
        clean = t.strip("'\"")
        norm = re.sub(r"^\./", "", clean).rstrip("/")
        first = norm.split("/")[0]
        dangerous = (
            norm in ("", "/", "~", "*", ".", "..")
            or clean.startswith(("/", "~", "$HOME", "${HOME}"))
            or ".." in norm.split("/")
            or "*" in first
            or norm.endswith(".git")
        )
        if clean.startswith(SAFE_RM_PREFIXES) and ".." not in norm.split("/"):
            continue
        if dangerous or first not in SAFE_RM_ROOTS:
            block("rm-rf",
                  f"`rm -rf {clean}` - recursive force-delete of a path outside the "
                  f"known-safe build artifacts ({', '.join(sorted(SAFE_RM_ROOTS))}).",
                  "delete precisely without -rf, or ask the user to confirm the exact path.")

    if re.search(r"\bchmod\s+(-[a-zA-Z]+\s+)*(-R|--recursive)\b[^;&|]*\b777\b", cmd) or \
       re.search(r"\bchmod\s+[^;&|]*\b777\b[^;&|]*(-R|--recursive)\b", cmd):
        block("chmod-777",
              "Recursive 777 makes everything world-writable.",
              "set the narrowest mode that works (644 files / 755 dirs).")

    # ---- 5. Remote code execution ----------------------------------------------------
    if re.search(r"\b(curl|wget)\b[^;&|]*\|\s*(sudo\s+)?(ba|z|k)?sh\b", cmd):
        block("curl-pipe-sh",
              "Piping a downloaded script straight into a shell executes unreviewed code.",
              "download it, read it, then run it deliberately.")

    # ---- 6. Secrets ------------------------------------------------------------------
    if re.search(r"\b(cat|bat|less|more|head|tail|strings|xxd|od|nl)\b[^;&|]*"
                 r"(\.env(\.[\w.-]+)?|\.pem|\.p12|\.pfx|id_rsa|id_ed25519|"
                 r"\.aws/credentials|\.npmrc|\.pgpass)\b", cmd):
        block("secret-read",
              "Reading a credentials file puts its contents into the transcript.",
              "reference the variable by name; ask the user for the value if truly needed.")

    # ---- 7. Deploys & production -----------------------------------------------------
    if re.search(r"\bterraform\s+destroy\b|\bcdk\s+destroy\b|\bsls\s+remove\b|"
                 r"\bserverless\s+remove\b|\baws\s+cloudformation\s+delete-stack\b", cmd):
        block("infra-destroy",
              "This tears down infrastructure, including stateful resources.",
              "never run by the agent. The user runs destroys themselves.")
    if re.search(r"\b(sam|cdk)\s+deploy\b|\bterraform\s+apply\b|\bserverless\s+deploy\b|"
                 r"\bsls\s+deploy\b|\bnpx\s+nx\s+run\s+\S+:deploy\b", cmd):
        block("deploy",
              "Deploys are outward-facing and need an explicitly named environment.",
              "show the plan/changeset and let the user run the deploy.")
    if re.search(r"\bdocker\s+system\s+prune\b|\bdocker\s+volume\s+(rm|prune)\b", cmd):
        block("docker-prune",
              "This deletes volumes and images other projects may depend on.",
              "prune the specific resource by name.")

    # ---- 8. Destructive SQL ----------------------------------------------------------
    if re.search(r"\b(psql|mysql|mariadb)\b[^;&|]*", cmd) and \
       re.search(r"\b(DROP\s+(TABLE|DATABASE|SCHEMA)|TRUNCATE\s+(TABLE\s+)?\w|"
                 r"DELETE\s+FROM\s+\w+\s*;)", cmd, re.IGNORECASE):
        block("destructive-sql",
              "Unbounded DROP/TRUNCATE/DELETE against a database.",
              "write it as a reviewed migration; never ad hoc from the shell.")

    # ---- 9. Repo-wide fan-out scripts ------------------------------------------------
    if re.search(r"\bnpm\s+run\s+(build|test|lint|test:unit|format)\b", cmd) and \
       not re.search(r"(-w\s|--workspace[=\s]|--filter[=\s])", cmd):
        block("repo-wide-script",
              "Repo-wide npm scripts fan out across every workspace and cost minutes.",
              "scope it: npx nx run <project>:<target>  (or npm run <script> -w <workspace>)")

    sys.exit(0)


if __name__ == "__main__":
    main()
