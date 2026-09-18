# Stage 3 Audit Report -- omegaconf-provenance

Auditor: independent pass, fresh context, no prior involvement in the build.
Package version audited: as delivered, THEN as fixed during this audit (all numbers
below are for the FIXED, final version unless explicitly marked "pre-fix"). Docker
was unavailable in this environment (`docker info` fails: no daemon socket); the
clean-room sequence was run at the host/venv level from a truly pristine
`git clone --no-local` of the committed base commit, per the task's explicit
instruction to treat that as an honest limitation, not as a verified Docker run.

================================================================================
14.1 VERDICT TABLE
================================================================================

| Gate | Verdict | Evidence |
|---|---|---|
| A | PASS | problem.md (498 words, 4 paragraphs) splits into ~60 atomic clauses (full inventory in section A below); every sentence maps to at least one clause, non-normative framing is zero. |
| B | PASS | Every clause I could isolate was falsified by a dedicated mutant and killed by a named test (67-mutant sweep, section D). Two mutants survive and are documented as equivalent/unreachable, not test gaps (see D). |
| C | PASS | Swept all ~77 hidden-test assertions; every one traces to a stated clause. Two soft spots noted as low-severity, non-blocking observations (provenance_diff's exact return shape; iter_provenance's path-escaping convention), not orphans -- both are the natural, only-sensible Python reading of a stated clause. |
| D | PASS | 67 mutants across all 5 families (4.1-4.5); 65 killed, 2 survivors confirmed genuine equivalent-code/unreachable-branch mutants by direct empirical tracing, not coverage gaps. One mutant (missing-source-into-untyped-leaf) surfaced a REAL bug in the reference itself, fixed at source. Full table in section D. |
| E | PASS | No message-string assertions (grep clean). One undisclosed exact-spelling contract found and fixed (`to_annotated_container`'s `value`/`provenance` keys) plus one undisclosed, untested behavioral contract found and fixed (`load()`'s absolute-path requirement, which the repo's own design note treats as an explicitly open question). No other undisclosed contracts, no contradictions, no unscoped rules found. |
| F | PASS | 498/500 words, plain ASCII, no title/headings/lists/code/paths/import-strings, opens with the ask, no motivational framing, prior-art re-verified independently in this pass (no provenance/blame/origin code, no PR, no branch touches it). |
| G | PASS | Every new symbol has a call site (itemized in section G); zero explanatory comments in new code (only pre-existing-idiom `# type: ignore` / `# noqa` pragmas, already used 40+ times elsewhere in the repo); no dead code beyond one documented, symmetry-only branch; no regressions (8554 passed / 363 skipped, unchanged before and after); the one bug found was a completeness gap on an edge path, now closed. |
| H | PASS | base is the real 8917-test suite, passing with and without the solution; new fails without solution (collection error, 77/77 real names with real diagnostics) and passes with it (77/77); no fail-fast flags; build-failure emitter verified to embed the actual pytest log per name, not a synthetic entry; test.sh parses `--output_path` before mode, cds to `/app`, selects tests by explicit path, exits with pytest's own status. |
| I | PASS | `test.patch`: 0 `--- a/` headers (new files only), `test.sh` mode 100755. `solution.patch`: no test files (grep clean). Both apply cleanly in the grader's order (`git apply test.patch && git apply --check solution.patch`, reverse, restore -- verified). Leak grep clean on both patches. Dockerfile: mars-base, `/app`, `COPY . .`, deps at build time, `CMD ["/bin/bash"]`, builds with neither patch applied, no network use introduced (grep clean for socket/requests/urllib). `repo_url.txt` carries the immutable commit hash. |
| J | PASS | Reference: 359 meaningful lines / 7 files. Minimal: effectively the same (359, argued below) -- the only two mutants that survive without being real gaps are same-line-count rephrasings, not removable lines, so nothing measurable can be stripped. Clears 350/3-file floor with full headroom. Named wall (operation-boundary attribution vs. the shared value-setting method) is backed by a REAL bug the reference itself had on first construction, which is strong evidence the wall is not a no-op. |
| K | PASS (4/4), with an honest limitation | Full clean-room re-run from a fresh `git clone --no-local` after every fix. b1 (base, no solution): 8917/0/0, PASS. n1 (new, no solution): pytest exit 2, 77/77 real test names with real captured collection-error diagnostics in each failure body (not synthetic), FAIL as required. b2 (base, solution applied): 8917/0/0, PASS. n2 (new, solution applied): 77/77, PASS. Run at the host/venv level, NOT inside the Docker image and NOT with `--network none`, because no Docker daemon is available in this sandbox (`docker info` fails on the socket). Dependency-install and test-execution behavior was verified not to need network access (no socket/requests/urllib introduced by the diff), which is the substance `--network none` protects; the literal Docker/network-isolation execution itself is unverified and is flagged here as a real limitation, not claimed as passed. |
| L | NOT RUN | No cohort/agent-run data exists yet. Per the spec, this is recorded as NOT RUN rather than PASS on static reasoning. |

================================================================================
14.2 DEFECT LIST
================================================================================

Severity key: HIGH = a wrong solution could pass, or the reference itself was wrong.
MEDIUM = a real coverage/fairness gap that would not by itself let a wrong solution
through given the OTHER tests, but is a genuine hole in the specific clause it
targets. LOW = residual risk noted for completeness, not acted on, with reasoning.

--------------------------------------------------------------------------------
DEFECT 1 -- Gate D / Gate G -- HIGH -- Real bug in the reference solution
--------------------------------------------------------------------------------
What: `BaseContainer._map_merge`'s per-key loop has two separate code paths for a
leaf value replace: one for typed ("has_ref_type") destinations, one for untyped
`AnyNode` destinations. The typed path correctly guards both the value AND the
provenance stamp behind `if not src_node_missing`. The `AnyNode` path (the far more
common case -- any plain, untyped YAML/Python scalar) did NOT guard the provenance
stamp at all: `node = copy.copy(src_node); node._set_value(dest_node._value())`
copied the MISSING source node's own provenance onto the destination's value,
silently violating problem.md's "a missing source leaves the target's record
unchanged" for the single most common merge shape.

Why it matters: this is not a hypothetical rival reading, it is what the shipped
reference actually did. It was invisible in the original 67-test suite because the
one test for this rule (`test_merge_missing_source_leaves_target_unchanged_c8081c`)
used `base = "a: 5"` / `override = "a: ???"` -- two single-line YAML docs whose "a"
key sits at the identical line/column, so the WRONG answer (override's record) and
the RIGHT answer (base's record) were value-equal by coincidence. The bug only
became visible after fixing the fixture collision (Defect 2).

Fix applied: stamp the destination's own provenance onto the value-only copy,
using the same shallow-copy-then-copy-the-metadata idiom this file already uses
elsewhere (`Node.__copy__`, base.py). Verified the fix does not alias/corrupt the
source node's own metadata (it does, via a plain `copy.copy`, share `_metadata`
by reference unless the copy is independently re-copied -- confirmed empirically
before and after). Added a dedicated test for the typed-leaf sibling path too
(`test_merge_missing_source_leaves_typed_leaf_unchanged_c8081c`), which was
already correct but had zero coverage.

--------------------------------------------------------------------------------
DEFECT 2 -- Gate D 4.6 (fixture discrimination) -- HIGH -- Systemic fixture collision
--------------------------------------------------------------------------------
What: seven tests built `base`/`override` YAML fixtures with identical structural
shape (same line count, same indentation, same-length key names), so the
`Provenance` record for the key under test was VALUE-EQUAL between the two sides
regardless of which one a given implementation actually picked. This is exactly
the "Formula collapse" / positional-degeneracy pattern the audit spec names:
strong-looking, numerous, green tests that discriminate nothing. Confirmed by
direct measurement (both sides' `get_provenance` calls compared for every merge
test) before any mutation was applied.

Affected tests (pre-fix): `test_merge_container_keeps_own_leaf_takes_source_c8081c`,
`test_unsafe_merge_matches_merge_semantics_c8081c`,
`test_merge_list_replaced_wholesale_takes_source_c8081c` (container AND item level),
`test_merge_container_vs_list_asymmetry_c8081c` (both keys),
`test_merge_three_way_sequential_c8081c` (all three pairwise comparisons),
`test_merge_with_instance_method_c8081c`,
`test_merge_missing_source_leaves_target_unchanged_c8081c` (this one hid Defect 1).

Why it matters: two mutants (list-wholesale-replace container-level stamp removal,
and a blanket "whole result takes the last input's origin" rival reading) survived
purely because of this, not because the code was right -- exactly the false-positive
failure mode Gate D exists to catch.

Fix applied: padded one side's YAML fixture with a leading, semantically-inert key
(`_pad_c8081c: 0`, or two such keys for the three-way case) so the compared
position can never coincide, and added explicit `!=` assertions against the losing
side in all seven tests as a second line of defense (per the spec's own guidance:
"prefer expected values that no plausible rival produces").

--------------------------------------------------------------------------------
DEFECT 3 -- Gate D 4.3 (partial-solution / edge path) -- MEDIUM -- Untested "null" merge fill
--------------------------------------------------------------------------------
What: problem.md states "filled in from missing, null, or an unresolved reference,
takes the supplying side's record" as three distinct triggers. Only "missing"
(partially) and "unresolved reference" were exercised for CONTAINERS; "null"
specifically -- at both the dict level (`_map_merge`'s top-of-function
`src._is_none()` branch, and the nested `dest_node._is_none()` expand branch) and
the list level (`_list_merge`'s `src._is_none()` branch and its
`src._is_interpolation()` sibling) -- had zero coverage. Four mutants removing
these exact stamps survived unnoticed.

Fix applied: five new tests, using an `Optional[Inner_c8081c]`/`Optional[List[int]]`
dataclass field to get a real, container-typed null (not a bare scalar), plus a
properly LIST-TYPED interpolation source (a scalar-typed interpolation source
bypasses `_list_merge` entirely via a different, already-covered code path, so the
list-interpolation test needed a `List[int]`-typed field specifically to reach it).

--------------------------------------------------------------------------------
DEFECT 4 -- Gate D 4.3 (edge path) -- MEDIUM -- Untested MISSING (not None) structured field, and new structured-typed key
--------------------------------------------------------------------------------
What: two further edge paths in `_map_merge` had zero coverage: (a) a nested
structured-config-typed field that is MISSING (`???`, not `None`) being filled by
merge -- this recurses through a DIFFERENT branch than the None case (the top-of-
function `dest._is_missing()` expand, reached only via the recursive
`dest_node._merge_with(src_node)` call, not the more commonly-hit `dest_node._is_none()`
check); (b) a brand-new key added during merge whose destination has a
structured-config ELEMENT TYPE (`Dict[str, Inner_c8081c]`), which takes an explicit-
promotion path with its own stamp, distinct from the plain-dict new-key case (which
is already correct "for free" via whole-node copy semantics and needed no stamp at
all -- confirmed by tracing, not by assumption).

Fix applied: two new tests (`test_merge_missing_structured_field_filled_by_source_takes_source_provenance_c8081c`,
`test_merge_new_structured_typed_key_takes_source_provenance_c8081c`).

--------------------------------------------------------------------------------
DEFECT 5 -- Gate D 4.3 / Gate G (overstated claim) -- MEDIUM -- Union-unwrap coverage overstated in difficulty.md
--------------------------------------------------------------------------------
What: difficulty.md claimed all four tree-walking helpers' shared union-unwrap fix
was "real, tested behavior (the hidden suite exercises Union-typed structured
fields explicitly)". A dedicated mutant per walker (disable ONLY that walker's
unwrap call) found: `iter_provenance_tree` and `to_annotated_container` were
already independently covered (killed immediately); `stamp_provenance_tree` was
REACHABLE but had zero coverage -- the one existing test with "stamp_provenance"
in its name actually exercises a DIFFERENT mechanism (`UnionNode._set_provenance`'s
own recursive propagation in base.py, hit via the ordinary merge leaf-replace path,
which already pre-dereferences the union before `stamp_provenance_tree` ever sees
it); `stamp_yaml_provenance`'s union-unwrap branch is UNREACHABLE through any
public API, confirmed by tracing: `create()`/`load()` only ever call it on a tree
built straight from parsed YAML, which never contains a `UnionNode` (union typing
is attached later, by a separate structured-config/merge step that uses a
different mechanism entirely).

Fix applied: added a test that reaches the real, previously-uncovered case for
`stamp_provenance_tree` -- a dotlist merge into an ALREADY-EXISTING container two
levels deep, so the RECURSIVE walk (which uses `_get_node`, not the pre-dereferencing
`_get_child` the top-level call site uses) is what gets exercised. Corrected
difficulty.md's claim to state, accurately, that the fourth walker's unwrap is
unreachable and is kept for symmetry rather than verified coverage -- an inaccurate
claim in a deliverable is itself a defect, distinct from the underlying code (which
needed no change: dead symmetry code that costs a couple of lines and matches an
established pattern is not worth stripping for a lower LOC count it does not need).

--------------------------------------------------------------------------------
DEFECT 6 -- Gate D 4.4 (rival reading R9) + Gate E 5.3 -- MEDIUM -- Undisclosed, untested absolute-path contract
--------------------------------------------------------------------------------
What: the reference calls `os.path.abspath()` on `load()`'s path argument, but (a)
the one test for this used `tmp_path`, which pytest already hands out as an
absolute path, so `os.path.abspath(p) == str(p)` trivially and the test could never
tell an "as-given" implementation from an "absolute" one; (b) problem.md never
said "absolute" -- and the repository's own design note
(`docs/design/provenance-tracking.md`, "Privacy / information exposure") explicitly
lists "whether provenance stores absolute paths, relative paths, or opaque source
identifiers" as an OPEN design question, so this is not derivable from the repo
either. This is a genuine hidden author contract by Gate E's own definition.

Fix applied: rewrote the test to `monkeypatch.chdir(tmp_path)` and call
`OmegaConf.load("cfg.yaml")` with a RELATIVE filename, asserting `os.path.isabs(...)`
and the exact resolved path. Added one clause to problem.md disclosing the
absolute-path requirement, written as a word-count-neutral rewrite of the existing
sentence (verified: still 498/500 words after this and Defect 7's fix).

--------------------------------------------------------------------------------
DEFECT 7 -- Gate E 5.3 -- LOW-MEDIUM -- Undisclosed exact dict-key names in to_annotated_container
--------------------------------------------------------------------------------
What: the hidden suite pins the exact output shape
`{"value": ..., "provenance": {...}}` at every level of `to_annotated_container`'s
output, but problem.md only said the record and value "come back together... at
every level," never naming the keys. Per Stage 2 section 7.3, an exact,
undiscoverable field spelling like this must be disclosed.

Fix applied: added "under keys named value and provenance" to the relevant
sentence in problem.md (net +6 words after two small compensating trims
elsewhere in the same document to stay under 500 words).

--------------------------------------------------------------------------------
NOTED, NOT FIXED -- Gate E / Gate C -- LOW -- two residual, defensible ambiguities
--------------------------------------------------------------------------------
- `provenance_diff`'s exact return shape (a mapping keyed by path, with a 2-tuple
  of (before, after) values, a missing side reported as `None`) is not spelled out
  character-for-character in problem.md. Judged as the natural, essentially only
  sensible Python reading of "reporting every path where their records differ" (a
  dict keyed by "path" is the idiomatic shape for "report X for every Y" in
  Python), consistent with `iter_provenance`'s disclosed (path, record) pairing.
  Not modified, given the very tight word budget and the low chance a competent
  solver reads this any other way -- but recorded here rather than silently
  passed over, since a stricter reviewer could reasonably disagree.
- `iter_provenance`'s output paths use the same backslash-escaping as `select`'s
  notation (tested by `test_iter_provenance_key_escaping_round_trip_c8081c`), but
  problem.md states "select's own notation" only for `get_provenance`'s INPUT, not
  explicitly for `iter_provenance`'s OUTPUT. Since the two must round-trip through
  each other by construction (the test itself asserts this), this is effectively
  forced rather than an independent hidden choice. Not modified.

--------------------------------------------------------------------------------
NOTED, NOT A DEFECT -- two confirmed equivalent/unreachable mutants
--------------------------------------------------------------------------------
- `m31` (dropping the `key == ""` disjunct in `get_provenance`'s root-query
  shortcut): confirmed by direct tracing that `Container._select_impl("")` already
  has its own built-in `if key == "": return self, "", self` short-circuit, so
  removing the OUTER shortcut changes nothing observable, at the root or at any
  sub-node. A true equivalent mutant, not a test gap.
- `u01` (stamp_yaml_provenance's union-unwrap): confirmed unreachable, see
  Defect 5. Left in the reference for symmetry with the other three walkers;
  documented rather than silently claimed as tested.

================================================================================
GATE A -- CLAUSE INVENTORY (evidence for the Gate A verdict)
================================================================================

problem.md, 498 words, 4 paragraphs, splits into the following atomic clauses
(grouped by paragraph; "universally quantified" clauses noted with *):

Para 1 (opening, 1 clause): C1 every config node can report where its current
value came from*; C2 that record survives everything the config is put through*
(elaborated by paragraph 4's specific list).

Para 2 (YAML/Python/dotlist origins, ~20 clauses): C3 YAML-file load reports the
file's absolute path; C4 ...and the line, counted from 1*; C5 ...and the column,
counted from 1*; C6 a scalar's position is its own start; C7 a block mapping's
position is its first key; C8 a flow collection's position is its opening
bracket; C9 a quoted string's position is its opening quote; C10 an alias reports
the anchored text's position, not the reference site; C11 a merge-key-pulled
value reports the anchor's position, not the reference site; C12 YAML-text
`create()` (no file) carries no file source; C13 a Python-built value is
distinguishable from a default; C14 a dataclass/attrs default value is "default";
C15 an explicit value equal to the default still counts as default; C16 ...
recursively into nested dataclass fields*; C17 dotlist entries report the exact
entry text; C18 CLI entries report the exact entry text; C19 a dotlist/CLI
entry's record covers any container structure it had to create; C20 a later
entry extending an already-created container leaves that container's own record
alone.

Para 3 (merge policy, ~16 clauses): C21 something replaced takes the supplying
side's record; C22 ...filled from missing, ditto; C23 ...filled from null,
ditto; C24 ...filled from an unresolved reference, ditto; C25 a key-by-key
merged mapping keeps ITS OWN record; C26 ...while its keys update underneath it;
C27 a key the merge adds takes the source's record; C28 a list (any type) is
never merged element by element; C29 replacing a list takes the source list's
record; C30 every element takes its matching source element's record, not a
fresh default; C31 a plain dict merge source counts as Python; C32 a plain list
merge source counts as Python; C33 direct assignment marks Python*; C34
appending marks Python*; C35 inserting marks Python*; C36 assignment/append/
insert always replaces whatever provenance was there.

Para 4 (preservation + union, ~8 clauses): C37-C41 copy/deepcopy/pickle/
masked-copy/interpolation-resolution never change any record*; C42 an
interpolation reports where its own expression was written; C43 ...never where
it resolves; C44 a value behind a union-holding type participates the same as
anything else, never skipped as an opaque wrapper*.

Para 5 (record/API shape, ~16 clauses): C45 the closed kind vocabulary is
exactly file/yaml/python/dotlist/default; C46-C50 the record type, its kind
field, optional source/line/column fields, and external readability; C51-C53
`get_provenance(cfg, key)` in select's notation, returns the record or an empty
answer; C54-C55 `iter_provenance` walks every reachable value, yields
(path, record); C56-C58 `provenance_diff(a, b)` reports every differing path,
including a path only one side has; C59-C60 `to_annotated_container` returns a
plain nested structure with record AND value/children together at every level
(now explicit: under "value"/"provenance" keys).

~60 clauses from 498 words -- well past the "five clauses from 480 words" warning
threshold in the spec, i.e., split far enough that coarse clauses are not hiding
untested behavior.

================================================================================
GATE D -- MUTANT SWEEP TABLE (condensed; full driver + raw results kept in the
scratchpad at .../auditD/run_mutants.py and .../auditD/results.json)
================================================================================

67 mutants across all five families. 65 killed. 2 survivors, both confirmed
equivalent/unreachable by direct tracing (m31, u01 -- see defect list above, "not
a defect"). Representative rows (full families all fully enumerated in the driver
script):

| # | Family | Mutant | Killed by | Verdict |
|---|---|---|---|---|
| m01-m03 | mechanical | YAML line/column off-by-one (both directions) | 10 position tests | KILLED |
| m04-m06 | mechanical | negate dict/list descent, drop union content propagation | 2-18 tests | KILLED |
| m08-m18 | mechanical | drop each of 11 distinct provenance-stamp call sites in `_map_merge`/`_list_merge`/`_tuple_merge` | 1-4 tests each, after Defects 2-4 fixes | KILLED |
| m20-m30 | mechanical | drop field-kind stamps, drop YAML-stamp calls in create/load, negate diff logic, drop dotlist stamps, no-op the key escaper | 1-25 tests each | KILLED |
| m31 | mechanical | drop empty-string shortcut in get_provenance | -- | SURVIVED (equivalent, documented) |
| s01-s11 | stub | trivial-return stub for every new function | 1-54 tests each | ALL KILLED |
| p01-p08 | partial-solution | omit each of the 7 files entirely; reading-half-without-writing-half | 1-75 tests each | ALL KILLED |
| u01-u04 | partial-solution (crosscutting) | disable union-unwrap in each of the 4 tree walkers individually | u01 survived (unreachable, documented); u02-u04 killed (u02 required Defect 5's fix) | 3/4 KILLED, 1 documented |
| r01,r02,r04-r11 | rival-reading (R1-R10 + fresh) | 0-based positions, key-position-not-value, blanket last-origin, no-restamp-on-assign, dotlist=python, raise-not-None, as-given-not-absolute, missing-overwrites (both leaf shapes), root-query-returns-None, resolution-moves-origin-to-target | 1-10 tests each, several required Defects 1/2/6 fixes | ALL KILLED |
| o01-o05 | over-rejection | reject empty yaml/mapping/sequence/dotlist-value/null-container | 1-42 tests each | ALL KILLED |

Rival models enumerated (from STAGE1's R1-R10 plus R11 for D10): 11. Discriminating
fixture present BEFORE this audit: 6 of 11 (R1, R2, R5, R7, R8, R11 killed on
first construction); 5 of 11 (R3 verified structurally rather than by mutation --
see below, R4, R6, R9, R10) required either a new fixture or a fix during this
audit. R3 (alias reports the alias/reference site) has no simple single-line
mutation available: PyYAML's `Composer` resolves `*anchor` to the IDENTICAL
composed `Node` object used for `&anchor` before this code ever sees it, so
there is no "alias's own site" data retained anywhere to redirect to -- verified
structurally (traced PyYAML's compose() behavior directly) rather than by
constructing a mutant, and documented here rather than silently skipped.

Over 40-60 mutants achieved (67); the family that started thin (partial-solution,
originally missed 2 real bugs) is now the strongest, per the spec's own guidance
that under-40 sweeps usually mean the over-rejection or partial-solution family
was skipped -- neither was skipped here, and the partial-solution family is what
actually found Defects 1 and 5.

================================================================================
GATE G -- DEAD-CODE / CALL-SITE ITEMIZATION
================================================================================

Every new symbol and its call site (all confirmed present, no orphans):
`Provenance`, `default_provenance()`, `Metadata.provenance`,
`Node._get_provenance`/`_set_provenance`, `Container._select_impl`'s
`resolve_interpolation` param, `UnionNode._set_provenance` -- base.py, used
throughout. `YamlPosition`, `_yaml_node_provenance`, `_build_yaml_position`,
`load_yaml_with_provenance` -- _yaml.py, called from omegaconf.py's create()/
load(). `select_provenance_node`, `_unwrap_union_node`, `stamp_yaml_provenance`,
`stamp_provenance_tree`, `_KEY_PATH_SPECIAL_CHARS`, `_escape_key_segment`,
`_append_provenance_key`, `iter_provenance_tree`, `_provenance_to_dict`,
`to_annotated_container` -- _impl.py, called from omegaconf.py's public API
methods. `OmegaConf.get_provenance`/`iter_provenance`/`to_annotated_container`/
`provenance_diff`, `OmegaConf.update`'s `_provenance` param -- omegaconf.py,
exercised by 77 hidden tests. `Provenance` export -- __init__.py, imported by the
hidden test file directly. One documented exception: `stamp_yaml_provenance`'s
`_unwrap_union_node` call is unreachable (Defect 5) -- the FUNCTION is fully
load-bearing and called; only this one internal branch never fires. Kept for
symmetry with the other three identically-shaped walkers rather than stripped,
which is a defensible idiomatic choice, not an unexplained artifact.

================================================================================
14.3 THE NUMBERS
================================================================================

- Reference meaningful LOC: 359 (Stage 2 counting script, re-run on the final
  regenerated solution.patch)
- Minimal meaningful LOC: 359, argued from Gate D -- the only two mutants that
  survive without being real gaps (m31, u01) are same-line-count alternate
  phrasings of an existing line, not removable lines, so nothing measurable can
  be stripped from the reference; every one of the other 65 mutants, including
  every whole-file omission (p01-p07), fails a test, so no row/file is optional.
- Files touched by the minimal solution: 7 (`omegaconf/base.py`, `_yaml.py`,
  `omegaconf.py`, `basecontainer.py`, `_utils.py`, `_impl.py`, `__init__.py`) --
  confirmed by Gate D's p01-p07 (each single-file omission fails 1-75 tests)
- problem.md word count: 498
- Clause count: ~60 (Gate A)
- Mutants generated / killed / survived: 67 / 65 / 2 (both survivors confirmed
  equivalent/unreachable by direct tracing, documented above, not defects)
- Clean-room result: 4/4, re-run after every fix, from a fresh
  `git clone --no-local`, host/venv level (Docker unavailable in this sandbox --
  see the Gate K row and the closing statement for the explicit limitation)
- Cohort: NOT RUN (Gate L) -- runs completed: 0, real failures: n/a, backfilled
  failures: n/a, solve rate: n/a, wall/secondary filter/near-miss count: n/a,
  median steps: n/a. No cohort data exists yet; this number set is intentionally
  empty rather than fabricated.

================================================================================
14.4 CLOSING STATEMENT
================================================================================

Gates A through K pass, with evidence, on the package as it stands after this
audit's fixes. The package is SUBMITTABLE.

Two things should be read alongside that verdict rather than smoothed over:

First, this audit found and fixed a REAL bug in the shipped reference solution
(Defect 1) -- not a hypothetical rival reading, but code that actually violated
a stated clause for the single most common merge shape, hidden by a systemic
fixture-collision problem (Defect 2) that independently affected seven tests.
Both are fixed at the source, both patches were regenerated from `git diff
--cached` (never hand-edited), and the full four-combination clean-room sequence
was re-run and confirmed 4/4 after the fix, as the spec requires. This is the
kind of finding a one-shot adversarial audit exists to catch, and it is exactly
why the spec insists on running it in a fresh context: nothing about the original
solve rate or difficulty argument changes on paper, but the guarantee that "the
reference is actually correct" did not hold before this pass.

Second, the Docker / `--network none` execution of Gate K's clean-room sequence
could not be verified in this environment, because no Docker daemon is available
(`docker info` fails to reach the socket). The equivalent host/venv sequence was
run instead, from a pristine clone, matching the Dockerfile's own install
command, and passed 4/4. The specific thing `--network none` protects against --
the solution or harness needing network access once dependencies are installed --
was independently checked by grepping the entire diff for socket/requests/urllib
usage (none found) and confirming test.sh performs no network calls. This is
offered as a real limitation, not papered over as a pass: the Docker-level run
itself is unverified and should be re-run in an environment with a working
Docker daemon before this is treated as fully closed.

Gate L is NOT RUN, per the spec's own instruction: no cohort or agent-run data
exists yet, and static reasoning about the expected 1-2/10 solve band -- however
well-argued in difficulty.md, and however much more credible it now is given
that the reference itself needed a real fix on a crosscutting interaction -- is
not a substitute for a real cohort run. The package is ready to be run against
a cohort; it is not yet calibrated.
