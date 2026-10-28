---
name: llm-evals
description: >
  Rules for measuring LLM features and agent setups: golden datasets, code and LLM-as-judge
  graders, regression evals in CI, cost and token tracking, and trigger evals for skills and
  subagents.
  Trigger: Changing a prompt, model, effort level or tool set; "does this prompt work", "build an eval", "why did quality drop"; adding a skill whose description must route correctly. Not for unit tests of deterministic code (use the repo's test runner), or for the API calls themselves (use `llm-apps`).
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

# LLM evals

## When to Use

- Before and after any change to a prompt, model, effort, tool list or retrieval.
- When an LLM feature ships for the first time: the eval is part of done.
- When a skill or subagent description changes: does it still load when it should, and
  only then?
- When someone says it "feels worse" and nobody can say by how much.
- For the interview-style workflow that builds an eval set and hill-climbs against it, the
  bundled `claude-api` skill has `/claude-api build-eval` and `/claude-api hillclimb`.

## Critical Patterns

### No prompt change without a number

A prompt is code whose tests are an eval. A change ships when the eval says it is at least
as good on the cases that matter and not more expensive, and not because three manual
tries looked fine. Record the baseline before touching anything.

### The golden dataset

1. **Real inputs first.** Sample production inputs or transcripts (jobfinder: 30 real
   offers) before inventing synthetic ones. Synthetic cases fill the gaps: edge cases,
   adversarial input, languages, empty fields.
2. **Labels by a human, once.** Each case has the expected output or the facts a correct
   answer must contain. The person who labels is not the prompt being tested.
3. **Cover the decision, not the average.** Include the cases where a wrong answer is
   expensive: the near-threshold score, the offer in another language, the injection
   attempt inside a job description.
4. **Version it in the repo** next to the prompt: `evals/<feature>/cases.jsonl`, one JSON
   object per line with `id`, `input` and `expected`.
5. **Split it.** A dev set you iterate on and a held-out test set you only score. Tuning on
   the test set turns it into a dev set.

### Graders, cheapest first

| Grader | Use when | Rule |
|--------|----------|------|
| **Exact / code check** | label, score band, JSON shape, a required field | always prefer it when the output is structured |
| **Reference match** | output must contain specific facts | check facts present and forbidden facts absent |
| **LLM-as-judge** | open-ended quality: tone, relevance, a cover letter | a rubric with 3-6 yes/no criteria, not a 1-10 vibe score |

Judge rules: a different, cheaper model than the one under test where possible; the rubric
and one good and one bad example in the judge prompt; output through structured outputs
(`{criterion: pass/fail, reason}`); and **calibrate it**: score 20 cases by hand and check the
judge agrees before trusting it.

### What every run records

- Pass rate per grader and per case tag, not only the average.
- Tokens in, out and cached, latency and cost per case and in total.
- Model id, effort, prompt version (git SHA) and dataset version.
- The failing cases themselves, so a regression is read, not guessed at.

Write results to a file per run (`evals/<feature>/runs/<date>-<sha>.json`) so two runs can be
diffed. Judge cost per completed task, not per request: a cheaper prompt that needs a retry
is not cheaper.

### Regression evals in CI

- A small, fast, deterministic slice (code graders, ~20-50 cases) runs on every PR that
  touches a prompt, model constant or tool definition, and fails the build below the
  recorded threshold.
- The full set with LLM judges runs nightly or on demand; it costs money, so it runs on
  purpose with a budget, never on every push.
- Thresholds live in the repo and only move in a reviewed commit with the run that
  justifies them.
- Pin the model id in the eval config. A model upgrade is its own PR with its own run.

### Trigger evals for skills and subagents

A skill's `description` is a router; test it like one.

1. Per skill, write 5-10 prompts that **should** load it and 5-10 near misses that **should
   not** (for `aws`: an SDK credentials question should, a Terraform IAM policy should not,
   that is `cloud-infra`).
2. Run each prompt headless (`claude -p "<prompt>" --output-format json`) in a scratch repo
   and check which skill or subagent was invoked.
3. Track precision and recall per skill. A description that triggers on everything costs
   context on every task; one that never triggers is dead weight.
4. Re-run the set whenever a description changes or a new skill overlaps an old one.

### Observability is an eval that never stops

Log per request in production: model, tokens, cache hits, latency, stop reason, cost, and a
sampled copy of input and output with personal data removed. Feed the sampled failures back
into the golden dataset. A support complaint that is not a test case yet will come back.

## Red Flags

A prompt changed with no eval run · only an average score reported · a 1-10 judge score
with no rubric · a judge never checked against human labels · the same model judging its own
output with no calibration · tuning on the test set · thresholds changed in the same commit
as the prompt with no run attached · full LLM-judged evals on every push · no cost recorded
per run · a skill description edited without its trigger prompts re-run · production
failures that never become test cases.

## Resources

- Bundled `claude-api` skill — `build-eval`, `hillclimb` and `cost-optimize` workflows.
- [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents)
