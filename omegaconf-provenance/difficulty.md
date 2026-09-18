# Difficulty

## Target and expected solve rate

Solve band: 1-2 of 10 attempts. Strongest tier at most once, never zero. This is a
crosscutting, single-repository attribution feature threaded through four different
places in the same library (YAML loading, node construction, the mutation boundary,
and merge) that all funnel through one shared value-setting method. The library itself
is small and readable (about 10k lines, existing suite runs in ~15s), and the
maintainers' own draft design note documents the target shape, so a capable agent that
reads the repo carefully can locate every change site. What separates 1-2 clears from 0
or from most agents is that the four sites interact: a fix that is locally correct for
one observable behavior systematically breaks another, and the failure only shows up in
a fixture that specifically targets that interaction (see "the named wall" below).

## Minimal-LOC-floor argument

Reference solution: 356 meaningful lines (per the Stage 2 counting script) across 7
files (`omegaconf/base.py`, `omegaconf/_yaml.py`, `omegaconf/omegaconf.py`,
`omegaconf/basecontainer.py`, `omegaconf/_utils.py`, `omegaconf/_impl.py`,
`omegaconf/__init__.py`). This clears the 350-line / 3-file floor with headroom in both
dimensions (7 files touched against a 3-file minimum).

Sub-behavior enumeration and where the minimal version of each must live:

1. Record type, storage on node metadata, and a point-query read API that resolves a
   select-style key path (dots, brackets, escapes, list indices) to a node's record or
   an empty answer -- `omegaconf/base.py` (record + storage), `omegaconf/omegaconf.py`
   (read API), `omegaconf/__init__.py` (export). ~45 lines. No solver can drop this: it
   is the only way any other row is observable at all.
2. YAML position capture during `load()` and `create(yaml text)`: start position for
   every scalar, mapping, and sequence, including alias and merge-key references
   resolving to the anchor's position, threaded into the nodes built one layer later --
   `omegaconf/_yaml.py` (position tree built from the loader's already-flattened,
   already-alias-resolved node graph) and `omegaconf/omegaconf.py` (stamping after
   construction). ~120 lines. Cannot be compressed below this because positions must be
   captured before the loader collapses the document to plain objects, then walked
   back onto a tree shape built independently by node construction.
3. Origin defaults for Python and structured (dataclass/attrs) creation, including the
   explicit-value-equal-to-default case counting as default, recursively into nested
   fields -- `omegaconf/_utils.py` (`get_dataclass_data`, `get_attr_data`). ~15 lines.
4. Dotlist and CLI stamping: each entry marks the node it sets, and any container it
   creates along the way, with that entry's own text; a later entry extending an
   already-created container leaves that container's own record alone --
   `omegaconf/basecontainer.py` (`merge_with_dotlist`), `omegaconf/omegaconf.py`
   (`update`). ~35 lines.
5. Mutation boundary: item/attribute assignment, append/insert/extend, and `update()`
   mark Python on the assigned subtree, including in-place updates of typed fields,
   while the same underlying value-setting call used by merge and by interpolation
   resolution must NOT mark Python -- `omegaconf/basecontainer.py`
   (`_set_item_impl`). ~60 lines. This is the row most agents underestimate, because
   the naive fix (stamp inside the shared setter) passes assignment fixtures and fails
   merge fixtures, or the reverse.
6. Merge policy across five internal paths (replace/fill takes the source's record; a
   container merged key-by-key keeps its own record while its keys update
   underneath; a key the merge adds takes the source's record; a list, of any type,
   merged wholesale takes the source list's record and every element takes its
   matching source element's record rather than a fresh default; a plain dict or list
   source counts as Python) -- `omegaconf/basecontainer.py` (`_map_merge`,
   `_list_merge`, `_tuple_merge`). ~70 lines. List/tuple element-level propagation
   specifically requires re-stamping after the container swap, because the existing
   list iterator unwraps scalar items to raw values even when not resolving, silently
   discarding the source item's record if the destination isn't re-stamped by hand.
7. Preservation through copy, deepcopy, pickle, masked copy, and interpolation
   resolution: none of these may change any record, and a resolved interpolation must
   still report where the interpolation expression itself was written, never the
   target it resolved to -- rides the existing `Metadata` deep-copy path plus a
   one-line check in the resolver. ~15 lines.
8. Position and kind rules distinguishing `create()` from YAML text versus `load()`
   from a path or file object -- `omegaconf/omegaconf.py`. ~20 lines.

Total: 380 estimated / 360 collapsed after folding rows 2+8 into one YAML-attribution
path and rows 5+6 around a shared stamping helper, matching the Stage 1 estimate. The
356-line reference lands within a few lines of that collapsed floor while also fixing a
correctness gap the floor estimate did not anticipate: none of the four tree-walking
helpers (position stamping, tree-wide stamping, provenance iteration, and the
annotated-container export) originally descended into a value sitting behind a
union-typed field, because they used the container's raw child accessor instead of the
one path in the codebase that already unwraps a union wrapper. Fixing that consistently
across all four walkers is included in the 356 and is real, tested behavior (the hidden
suite exercises Union-typed structured fields explicitly), not padding.

Collapse questions, answered against the real code:
- What can be dropped? Nothing. Each row above has a dedicated fixture in the hidden
  suite, and removing any row's implementation makes that fixture fail while every
  other row's fixtures keep passing -- confirmed by stashing each file individually
  during development and observing which fixtures broke.
- What can be folded? Rows 2 and 8 share one YAML-attribution code path (a single
  loader entry point used by both `load()` and `create(text)`); rows 5 and 6 share one
  stamping helper invoked from both the mutation boundary and the merge paths. Both
  folds are already reflected in the reference and in the 360-line collapsed estimate.

## The named wall

The wall: origins must be attributed at the operation boundary, not inside the shared
value-setting method. That method is called by direct user assignment, by merge of
typed fields, by interpolation resolution, and by container expansion -- only the first
two are origin-changing events, and they need different origins (Python for assignment,
the source node's record for merge). At the same time, YAML positions can only be
captured before the loader flattens the parsed document to plain Python objects, yet
must end up attached to nodes that get built two layers later, by code that has no idea
whether it is being called from a fresh load or from ordinary node wrapping.

Bite test, in writing:
- A solver who stamps "python" unconditionally inside the shared value-setting method
  passes every create/load/assignment fixture and fails resolve-preserves-origin,
  typed-field merge, and dotlist fixtures.
- A solver who stamps only at the node-wrapping call site (the layer above value-setting)
  passes file-load and plain-Python fixtures and fails in-place typed-field updates and
  whole-list replacement, because those paths reuse the value-setting method directly
  without going through node-wrapping again.
- A solver who records YAML positions keyed by container identity only (skipping
  scalars) passes every container-position fixture and fails every scalar-position
  fixture.
- A solver who copies origins during merge by copying whole nodes wholesale passes
  value-replacement fixtures and fails the typed-field-updated-in-place and
  list-expansion fixtures, where no whole node is ever copied.

At least one in ten clears it: the repository is small and readable, the design note
already in the repo lays out the intended shape and read-API name, the existing suite
runs in about 15 seconds so iteration is fast, and every tie-break an implementer needs
is stated in problem.md. At most two in ten clear it: eight sub-behaviors whose correct
implementations interact non-locally (stamping at the boundary that fixes the naive
loader path breaks the mutation-boundary fixtures; threading positions through
`create()` touches the same node-wrapping code the mutation boundary also depends on),
so a fix that is locally verified against one behavior's fixtures routinely regresses
another's, and the interaction is only visible once both fixture groups exist and are
run together.

## Disclosure list and argument that disclosure did not collapse difficulty

Disclosed in problem.md:
- The record type's existence and shape: a small record with a `kind` field holding one
  of five words (`file`, `yaml`, `python`, `dotlist`, `default`) plus optional `source`,
  `line`, and `column` fields, readable from outside -- referred to as "something like
  Provenance."
- Four API names and their signatures in plain words: a point-query method taking a
  config and a key path in select's own notation ("something like get_provenance"), a
  full-tree walk yielding path/record pairs ("iter_provenance"), a two-config comparison
  by path ("provenance_diff"), and a whole-config-to-nested-structure export carrying
  record and value/children together at every level ("to_annotated_container").
- The five kind words themselves, since the hidden suite asserts on them exactly and
  they are not derivable from the repo (the repo's own design note only sketches
  "file"/"line"/"column" informally, not a closed vocabulary).
- The full merge policy in prose (Choice points D1-D10 from the Stage 1 record), since
  which side of a merge "wins" a record is exactly the kind of undiscoverable author
  contract Stage 2 section 7.3 requires disclosing.

Not disclosed, and left as real work: how positions are actually captured during YAML
parsing (before or after alias resolution, where in the loader the hook belongs), how
the shared value-setting method is kept neutral between origin-changing and
non-origin-changing callers, how the five internal merge paths are told apart and
mapped to the stated policy, and how a value sitting behind a union-typed field is
reached by all four tree walkers. Disclosing the record shape and API names lets a
solver know what to build; it says nothing about where in the four call sites listed
under "the named wall" the attribution decision has to be made, which is the entire
difficulty of the task. The `absolute_key` parameter accepted by the read API mirrors
`select()`'s own existing parameter of the same name and is deliberately left
undisclosed and untested at `True`, since it is discoverable by analogy to public API
the solver already has to read.

## Excluded upstream tests

None. The existing `tests/` directory is used unmodified and in full as the `base`
regression check; no upstream test was slow, flaky, or network-dependent enough to
warrant exclusion. Two existing test modules (`tests/test_utils.py`,
`tests/interpolation/test_custom_resolvers.py`,
`tests/interpolation/test_resolver_annotation_validation.py`) depend on the
`pytest-mock` fixture and one (`tests/test_tuple_structured.py`) depends on
`typing_extensions`; both are installed in the Dockerfile so the full existing suite
collects and passes at base, matching upstream CI's own dependency set for running
`tests/`.

## G1-G12 verdicts, carried from the lock record and updated with what the build revealed

- G1 PASS. Estimated 380 / collapsed 360 meaningful lines at lock time; the built
  reference lands at 356, confirming the collapsed estimate and clearing the 350-line
  floor with room (7 files against a 3-file floor).
- G2 PASS. The six seams named in the lock record held exactly as scoped; no seventh
  seam was discovered during the build.
- G3 PASS. The read API returns a structured record (kind/source/line/column); no
  hidden test asserts on rendered text or message strings.
- G4 PASS. YAML-position expectations in the hidden suite are computed independently
  from fixture text via `yaml.compose()`, not read off the reference's own output;
  merge-attribution and kind expectations follow directly from the stated merge order
  and operation performed.
- G5 PASS, strengthened. The maintainers' own draft (`docs/design/provenance-tracking.md`,
  issue #1173) still names the intended read-API shape and kind/source/line/column
  model with zero linked implementation, confirmed unchanged at build time.
- G6 PASS. All attribution logic lives in the 7 changed files; the one dependency-level
  fact the hidden suite relies on (PyYAML mark semantics) is exercised through public
  `yaml.compose()`, not through omegaconf internals.
- G7 PASS. The wall is named above with a written bite test covering four distinct
  wrong-boundary implementations, each shown to pass one fixture group and fail
  another.
- G8 PASS, and the build surfaced a fifth change site beyond the four listed at lock
  time: all tree-walking helper functions (position stamping, tree-wide stamping,
  provenance iteration, and the annotated-container export) needed a shared
  union-unwrapping fix, discovered by a targeted union-typed-field fixture during
  development. Fixing one such helper without fixing the others left three of the four
  silently stopping at a union-wrapped field; this interaction is now itself part of
  the crosscutting difficulty and covered by dedicated fixtures.
- G9 PASS. Disclosure is limited to the record shape, the four API names, the five
  kind words, and the merge policy in prose; every mechanism listed under "the named
  wall" remains unstated and unimplemented until the solver writes it.
- G10 PASS. No existing test constructs `Metadata`/`ContainerMetadata` directly; the
  added `provenance` field is defaulted, so every existing constructor call and every
  pickled object created within a test run keeps compiling and round-tripping
  unchanged. Confirmed by the full existing suite passing unmodified at both base and
  with the reference applied.
- G11 PASS. All ten choice points (D1-D10) from the lock record are both implemented
  and stated in problem.md; none were dropped or added without disclosure during the
  build.
- G12 PASS. No network, clock, locale, or filesystem-ordering dependence; YAML fixtures
  are inline strings or `tmp_path`-scoped files with fixed content. The hidden suite of
  67 tests runs in well under a second; the full existing suite plus the hidden suite
  together run in under 20 seconds.
