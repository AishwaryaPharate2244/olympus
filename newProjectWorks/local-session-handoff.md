I'm building a long-horizon coding-agent benchmark task (Stage 1: pick and lock an idea) on
ayrat555/fang, a Rust job-queue library. I have three spec files governing this — S1-find-idea.md,
S2-build-challenge.md, S3-audit-challenge.md — make sure they're in this project folder before
we go further; follow them exactly, especially S1 section 9 (kill gates G1-G12) and section 12
(output format). Never use "olympus", "quest", "challenge", or similar platform terms as
identifiers, comments, or test/variable names in any code, test, or problem.md we produce.

REPO ALREADY SCREENED AND LOCKED IN:
  github.com/ayrat555/fang, commit c7cc3679e845d3a6b03f33836cb6bc097caa5b56 (2026-07-02)
  License: MIT (file is named LICENCE, British spelling), copyright Ayrat Badykov 2022 — on
    the allowed list.
  722 stars at screening time (recheck live), not on my disallowed_repos.csv, no known
    ecosystem-centrality red flag (not embedded as a dependency inside a major platform, unlike
    an earlier candidate I dropped for exactly that reason).
  OPEN ITEM: rough language-mix pass came out ~87% Rust by line count across the whole clone
    (5549 Rust lines vs 824 non-Rust in toml/sql/md/yml, done before I found the real src
    layout) — that's a bit under the ~90% comfort bar. Recompute properly scoped to
    fang/fang/src/ before relying on it.

REPO LAYOUT:
  Cargo workspace at repo root. Core crate lives at fang/fang/ (i.e. <repo-root>/fang/Cargo.toml,
  <repo-root>/fang/src/...). fang-derive-error/ is a small proc-macro crate. 3 separate migration
  dirs at fang/fang/{postgres,mysql,sqlite}_migrations/, all creating a table called fang_tasks
  with backend-specific column types (uuid vs BLOB, jsonb vs TEXT, native enum vs
  CHECK-constrained TEXT, TIMESTAMPTZ vs unixepoch INTEGER).

THE CORE ARCHITECTURAL FINDING (this is the seam worth building on):
  src/blocking/ and src/asynk/ are TWO FULLY INDEPENDENT implementations of the same job-queue
  concept — blocking/ uses Diesel (sync), asynk/ uses sqlx (async/tokio) — and BOTH read/write
  the same fang_tasks table. Zero shared code between them. Zero existing test exercises both
  against the same scenario (confirmed: grepping for "asynk" inside blocking/*.rs and
  "blocking::" inside asynk/*.rs returns nothing outside test-irrelevant contexts).

  Three parity-critical contracts I've traced so far, all independently re-implemented on both
  sides with nothing enforcing agreement between them:
    1. RetentionMode (KeepAll/RemoveAll/RemoveFinished) — defined once in lib.rs, but
       interpreted separately in blocking/worker.rs::finalize_task and
       asynk/async_worker.rs::finalize_task. I read both in full: CURRENTLY behaviorally
       identical (same match arms against Ok/Err). Not a current bug — an unenforced parity
       contract with no test that would catch future drift.
    2. uniq_hash deduplication — computed independently via a calculate_hash function in
       blocking/queue.rs and a separate calculate_hash in asynk/backend_sqlx.rs (sha2 is a
       shared dependency). NOT YET VERIFIED whether these two produce identical hashes for the
       same metadata — check the exact serialization + hashing steps on both sides. This is the
       single highest-value open thread: if they diverge even slightly (e.g. JSON key
       ordering), a task marked unique via one mode could silently fail to dedupe against the
       other mode's insert, which is a concrete, testable, real bug rather than a hypothetical
       parity risk.
    3. Retry/backoff — Runnable::max_retries()/backoff() (blocking/runnable.rs, 53 lines) vs
       AsyncRunnable::max_retries()/backoff() (asynk/async_runnable.rs, 82 lines). The line-
       count gap looked suspicious but is mostly async_trait boilerplate and extra
       From<sqlx::Error>/From<serde_json::Error> impls asynk needs and blocking doesn't — the
       actual trait methods and default impls (RETRIES_NUMBER=20, backoff = 2^attempt) are
       identical, and both worker run-loops call them the same way (schedule_retry if
       retries < max_retries, else finalize). Also currently parity-clean.
    4. NOT YET CHECKED: cron scheduling (Scheduled::CronPattern) parity between
       blocking/worker.rs's run_tasks (calls queue.schedule_task on the actual_task) and
       whatever the asynk equivalent is — I hadn't gotten to this before switching over.

IMMEDIATE NEXT STEPS, IN S1 ORDER:
  1. Section 2: run the existing test suite and get it green BEFORE anything else — I had not
     done this yet. Check .env and the Makefile for how tests are normally run (feature flags,
     whether integration tests need a live Postgres/MySQL, or whether SQLite-backed tests can
     run hermetically). This directly feeds G12 (hermeticity) — if the interesting
     blocking-vs-asynk parity tests need to run against something other than SQLite to be
     representative, that's a real tension to resolve early, not late.
  2. Finish the uniq_hash hash-comparison (item 2 above).
  3. Check cron scheduling parity (item 4 above).
  4. Complete the section 3 six artifacts properly: subsystem map, seam census (the
     blocking/asynk parity seam is the strongest lead), observation map (existing test idioms
     in blocking/queue/queue_tests.rs and asynk/async_queue/async_queue_tests.rs), depth map,
     surface inventory (Task struct fields/exportedness — it already derives Queryable/
     Identifiable under the blocking feature, worth checking what that implies for any new
     pinned symbol), prior-behavior check.
  5. Section 4 prior-art sweep — check fang's GitHub issues/PRs/branches for anything about
     blocking/asynk parity or uniq_hash bugs. I couldn't reach the GitHub API from the cloud
     session (scoped to an attached repo only) — should be unrestricted locally.
  6. Generate 6-10 candidates, kill against section 6 anti-patterns and section 9 gates G1-G12.
     Pay special attention to G4 (need a clean answer-key — note that the OTHER mode's already-
     tested behavior can serve as the independent ground truth for whatever gets changed on one
     side, which is an unusually clean G4 story if the idea is shaped as "make X agree with the
     already-correct Y") and G12 (avoid the graded test surface needing a live Postgres/MySQL).
  7. Lock exactly one idea with 1-2 runners-up, write the full section 12 idea-lock record.

Also keep the screening constraints live in case this repo dies at some gate: stars <=1000,
license must exact-match the closed Appendix C list, real commit within 12 months, ~90%+ one of
Go/Rust/Python/TS-JS/C++, and cross-check any replacement candidate against
disallowed_repos.csv again.

Start by cloning github.com/ayrat555/fang at c7cc3679e845d3a6b03f33836cb6bc097caa5b56 and running
its test suite.
