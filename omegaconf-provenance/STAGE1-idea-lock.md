Olympus -- Stage 1 idea-lock record
Host: omry/omegaconf

0. HOST SELECTION HISTORY
-------------------------
The first pass locked tobymao/sqlglot (window functions in the Python executor). The
requester rejected that host for popularity (9.6k stars) and set a 500-3k star band.
Hosts screened and killed in the band: textX (HEAD needs an unreleased Arpeggio 3.0, and
the model-to-text idea lands in one new module: G2), pg-mem (tests run only under bun),
pint (HEAD requires Python 3.12 and the open log-unit design is unsettled: G5/G3),
jmespath.py (JEP set floor ~335 lines and a public community port: G1/G7), goawk (no
POSIX gap; interp tests exec gawk), mongomock (ISC, no commits in 12 months), fakeredis
(460 stars), csvq (last commit 2023), go-mysql-server (5.2M lines, Go 1.26 toolchain),
glom (small remaining gaps), traitlets (kept as backup, no gap found in time).

1. REPOSITORY
-------------
Repo            https://github.com/omry/omegaconf
Commit          4cee6d63d850ef1f8e003f093711971f2924e280  (2026-09-10 23:16:56 +0200)
License         BSD 3-Clause, read at LICENSE (full BSD-3 text, copyright Omry Yadan)
Stars           2.4k (GitHub page, fetched 2026-09-17)
Language mix    Python: omegaconf/ 10,219 lines plus tests; the only non-Python source
                is 227 lines of ANTLR grammar (.g4) whose generated Python is checked in
                under omegaconf/grammar/gen. Python share > 99%.
Activity        212 commits in the last 12 months, 64 unreleased news fragments, 0 open PRs.
Existing suite  python -m pytest tests: 8528 passed, 363 skipped, 13.3s (Python 3.12,
                PyYAML 6.0.3 with C loader). tests/test_tuple_structured.py needs the
                typing_extensions test dependency; with it installed: 26 passed.
Runtime deps    PyYAML>=5.1.0 only (antlr4 runtime is vendored). python_requires>=3.10.
Hermeticity     no network reference in tests/; YAML fixtures are written to tmp paths.

Section 2 checklist: license [x] recency [x] stars [x] production suite green [x]
language >= 90% [x] immutable hash [x] deterministic oracle (OmegaConf public API,
structured return values) [x] hermetic [x].

2. BEHAVIORAL GOAL
------------------
Every node of a config must know where its current value came from, and that knowledge
must survive everything a config goes through. A config loaded from a YAML file reports,
for any key path, the file and the line and column where that value begins. A config
built from Python objects reports Python as the origin. Entries applied from a dotlist
or the command line report the entry that produced them. When configs are merged, each
node reports the input that supplied its current value: replaced or filled values take
the later input's origin, containers merged key by key keep their own, keys added take
the source's. Assigning from Python replaces the origin of what was assigned. Copying,
deep-copying, pickling, masking and resolving interpolations never change origins. The
maintainers' own draft (docs/design/provenance-tracking.md, issue #1173) describes this
feature and names the read API; nothing implements it.

3. SUB-BEHAVIOR ENUMERATION (G1 litmus)
---------------------------------------
  Sub-behavior                                          Lives in                  Min LOC  New?
  ----------------------------------------------------  ------------------------  -------  ----
  1 Provenance record carried by node metadata,         omegaconf/base.py,           45    no
    exported, and a read API that resolves a select-    omegaconf/omegaconf.py,
    style key path (dots, brackets, escapes, list        omegaconf/__init__.py
    indices) to the node's record or None
  2 YAML positions: capture start marks for every       omegaconf/_yaml.py,          120   no
    scalar, mapping and sequence during load() and       omegaconf/omegaconf.py
    create(yaml text), including aliases and merge       (create path),
    keys, and thread them into the nodes created for     dictconfig.py/listconfig.py
    nested containers and list items                     (construction)
  3 Origin defaults for Python/structured creation      omegaconf/omegaconf.py        15    no
  4 Dotlist and CLI: each entry stamps the node it       basecontainer.py              35    no
    sets and any container it creates on the way with    (merge_with_dotlist),
    that entry's text                                    omegaconf.py (update)
  5 Mutation boundary: item/attribute assignment,        basecontainer.py              60    no
    append/insert/extend and update() stamp Python on    (_set_item_impl),
    the assigned subtree, including in-place updates of  dictconfig.py, listconfig.py
    typed nodes, while internal value setting (merge,
    resolution) does not
  6 Merge policy: replaced/filled values and containers  basecontainer.py              70    no
    take the source's record; key-by-key containers      (_map_merge, _list_merge)
    keep theirs; typed fields updated in place take the
    source's; list replacement takes the source list's;
    missing sources leave records untouched; plain
    dict/list sources count as Python
  7 Preservation through copy/deepcopy/pickle/masked     nodes.py, dictconfig.py,      15    no
    copy and interpolation resolution                    listconfig.py, _impl.py
  8 Position and kind rules for create() from YAML       omegaconf/omegaconf.py        20    no
    text versus load() from a path or file object
  ----------------------------------------------------  ------------------------  -------  ----
  TOTAL                                                                            380   7 files

Collapse question 1 (what can be dropped): nothing. Each row has fixtures planned: 1 by
every test; 2 by nested-mapping, list-item, flow-style, alias and merge-key positions;
3 by structured-config and dict creation; 4 by dotlist entries creating paths; 5 by
assignment after load, append/insert, update on typed fields, and the resolve-does-not-
restamp case; 6 by merge over loaded files with replaced, kept, added, typed, listed and
missing keys; 7 by deepcopy/pickle/masked_copy; 8 by create(text) versus load(path).
Collapse question 2 (fold rows): 2 and 8 fold into one YAML attribution path (130 for
140); 5 and 6 can share a stamping helper (120 for 130). Collapsed total: 360 across 7
files. Passes G1 with modest headroom; the reference is expected at 480-600 lines.

4. CROSSCUTTING MAP
-------------------
Seams (what two subsystems must agree on, and what enforces it today):
  S1 Load seam: OmegaConf.load() and create(str) parse YAML to plain dict/list objects
     (omegaconf/_yaml.py loader, omegaconf.py) and only then build nodes via create();
     positions are discarded at this boundary. Enforced by nothing.
  S2 Node-construction seam: DictConfig/ListConfig._set_value_impl -> __setitem__/append
     -> BaseContainer._set_item_impl -> _maybe_wrap/_node_wrap build the tree; every
     origin must be assigned here without knowing which public operation is running.
  S3 Value-setting seam: Node._set_value is shared by user mutation (the
     should_set_value path in _set_item_impl), merge of typed nodes
     (dest_node._set_value(src_value) in _map_merge), resolution (_impl._resolve) and
     expand(); only some of these are origin-changing events. Enforced by nothing.
  S4 Merge seam: _map_merge / _list_merge copy nodes (dest[key] = src_node), update
     typed nodes in place, expand None/missing/interpolated containers, and skip missing
     sources; provenance policy must be applied consistently across these five paths.
  S5 Metadata seam: Metadata/ContainerMetadata is deep-copied by container __init__ when
     wrapping an existing config, by __deepcopy__, and pickled via __getstate__; a
     provenance field must ride this path or be lost on OmegaConf.merge (which
     deep-copies its first input) and on copy.
  S6 Key-path seam: select/update/from_dotlist share split_key and _select_impl for
     dots, brackets, escapes and list indices; the read API must use the same path
     semantics and the dotlist stamping must follow the path update() walks.
Files that must change: omegaconf/base.py, omegaconf/_yaml.py, omegaconf/omegaconf.py,
omegaconf/basecontainer.py, omegaconf/dictconfig.py, omegaconf/listconfig.py,
omegaconf/__init__.py (export), optionally omegaconf/_impl.py and nodes.py.
Why one new module cannot absorb it: origins are decided at four different places that
already exist (YAML construction, node wrapping, the mutation boundary, merge) and a
side module can only read what those places recorded; the wall is precisely that the
shared _set_value path must NOT stamp origins while three of its callers must.

5. ORACLE DESIGN
----------------
Observation: OmegaConf.get_provenance(cfg, "a.b[0]") returns a record with readable
fields kind, source, line, column (or None for an absent path). Tests assert exact
tuples (kind, source, line, column) and exact equality of records across copies.
Independent ground truth (G4): YAML positions are facts of the fixture text (counted by
hand and cross-checked with PyYAML's own marks in the test file, never with the
reference); merge attribution is a fact of the merge order; Python/dotlist kinds are
facts of the operation performed. A slow model in the test file recomputes expected
positions from the fixture strings with yaml.compose(), independent of the reference.

6. CHOICE POINTS AND TIE-BREAKS (to be stated in problem.md)
-----------------------------------------------------------
  D1 Lines and columns are counted from 1.
  D2 A value's position is where its own YAML node begins, not its key: for a nested
     block mapping that is its first key; for a flow collection the opening bracket;
     for a quoted scalar the opening quote.
  D3 An alias reports the position of the anchored node it refers to; keys pulled in
     through a merge key keep the anchored node's positions.
  D4 load(path) records the absolute path; load(file object) records the object's
     name attribute; create(yaml text) records kind "yaml" with no source.
  D5 A dotlist entry's record carries the entry text exactly as given; containers
     created implicitly along its path carry the same entry.
  D6 Merge: a value replaced or filled (from missing, None or an interpolation) takes
     the source node's record; a container merged key by key keeps its own; a list
     replaced wholesale takes the source list's record and its items theirs; a typed
     field updated in place takes the source's; a missing source leaves the target's
     record unchanged; a plain dict or list source counts as Python.
  D7 Assignment from Python (item, attribute, append, insert, extend, update) stamps
     Python on the assigned node and everything created beneath it.
  D8 Resolving an interpolation, deep-copying, copying, pickling, masked_copy,
     to_container and to_yaml never change any record.
  D9 An interpolation node reports where the interpolation text was written, never
     the node it refers to.
  D10 get_provenance with no key reports the root container.

7. DISCLOSURE LIST
------------------
  - Read API name and shape: OmegaConf.get_provenance(cfg, key=None) returning a record
    with readable fields kind, source, line, column; None for an absent path. Key path
    syntax identical to select.
  - Kind vocabulary: "file", "yaml", "python", "dotlist".
  - Source and position semantics per kind (D1-D5).
  Argument that disclosure does not collapse difficulty: the record shape says nothing
  about how positions are captured, how the shared value-setting path is kept neutral,
  or how merge paths are told apart; those are the work.

8. SECOND-READING LIST
----------------------
  R1 Positions are 0-based like PyYAML marks. Ruled out by D1.
  R2 A container's position is its key's position. Ruled out by D2.
  R3 An alias reports the alias site. Ruled out by D3.
  R4 After merge the whole result carries the last input's origin. Ruled out by D6.
  R5 Assigning a Python value keeps the node's old origin. Ruled out by D7.
  R6 Resolving an interpolation moves the origin to the target. Ruled out by D8/D9.
  R7 Dotlist entries are Python. Ruled out by D5.
  R8 get_provenance raises on an absent key. Ruled out: returns None.
  R9 load records the path as given. Ruled out by D4 (absolute).
  R10 A missing (???) source overwrites the origin. Ruled out by D6.

9. GATE VERDICTS
----------------
  G1  PASS  380 estimated / 360 collapsed meaningful lines across 7 existing files.
  G2  PASS  six seams; the wall lives in the shared _set_value path (S3) and the merge
            paths (S4); YAML positions cross S1 and S2.
  G3  PASS  structured record via public get_provenance; no message text, no internals.
  G4  PASS  ground truth from fixture text positions (recomputed with yaml.compose in
            the test), merge order, and operation kind.
  G5  PASS  docs/design/provenance-tracking.md (Draft, 2026-04-24) is the maintainers'
            own design for exactly this, tracking issue #1173 (open, wishlist); it names
            OmegaConf.get_provenance and the kind/source/line/column model.
  G6  PASS  all logic in-repo; PyYAML marks are a public API of the dependency and the
            test's cross-check uses yaml.compose, not omegaconf internals.
  G7  PASS  wall named in section 10; bite test written.
  G8  PASS  change sites: loader, create, node wrapping, mutation boundary, merge,
            read API; fixing one exposes the next (see section 10).
  G9  PASS  disclosure is the API shape and kind vocabulary; all mechanics remain open.
  G10 PASS  no existing test constructs Metadata/ContainerMetadata directly; adding a
            defaulted field keeps every constructor call compiling; pickled objects
            from the suite are created within the same run.
  G11 PASS  see section 12.
  G12 PASS  no network, clock, locale or filesystem-order dependence (fixtures written
            to tmp_path with fixed content); hidden suite runs in seconds.

10. BAND ARGUMENT
-----------------
The wall: origins must be attributed at the operation boundary, not in the shared
value-setting path. Node._set_value is called by user assignment, by merge of typed
fields, by interpolation resolution and by container expansion; only the first two are
origin-changing, and with different origins (Python versus the merge source). At the
same time YAML positions can only be captured before the loader flattens the document
to plain objects, and must reach nodes that are created two layers later.
Bite test: a competent solver who stamps "python" inside _set_value passes every
create/load/assignment fixture and fails resolve-preserves-origin, typed-field merge
and dotlist fixtures; a solver who stamps only in _node_wrap passes file and Python
fixtures and fails in-place typed updates and whole-list replacement; a solver who
records positions only for containers (keyed by object identity) passes container
fixtures and fails every scalar position; a solver who copies origins on merge by
node copy alone passes value replacement and fails the typed-field and expand cases.
At least one in ten clears it: the code is 10k readable lines, the suite runs in 13s,
the design note in the repo lays out the model, and every rule is stated. At most two
do: eight sub-behaviors whose fixes interact (stamping at the boundary breaks the
naive loader path; threading positions through create changes the wrapping code that
the mutation boundary also uses).

11. MINIMAL-SOLUTION ESTIMATE
-----------------------------
360-380 meaningful lines across 7 files. Reference expected at 480-600 lines.

12. PRIOR-ART EVIDENCE
----------------------
  In-repo   rg -n -i 'provenance|blame|origin' omegaconf/*.py -> only typing.get_origin.
            Metadata has no source fields; load() discards YAML marks (omegaconf.py
            load -> yaml.load -> create). docs/design/provenance-tracking.md is a
            Draft with "Implementation shape" only; docs/design/README.md lists it
            under "Draft and planned design work"; no code.
  Upstream  GitHub PR search (provenance OR blame OR "source location" OR "line
            number" OR lc): four unrelated merged PRs (#1323, #647, #545, #454).
            Open PRs: none ("There aren't any open pull requests"). Issue #1173
            "Consider adding config 'blame' metadata": open, label wishlist, no
            comments, no linked PR. Remote branches: 1.4/2.0/2.1/2.2/2.3/2.4 release
            branches, pr1347 (ListConfig insert fix), backlog-atlas (generated backlog
            snapshots, no code); none touch provenance.
  Host      first challenge on this host; no taxonomy row taken.
  Global    no similarity tool available; by mechanism this is repo-specific
            attribution threading through this library's loader, wrapping, mutation
            and merge paths, not a generic exercise.

13. TAXONOMY
------------
Row: trace / attribute / explain a decision (which input produced each value). Nearest
alternative row: compose / overlay layered configuration. No other challenge on this
host.

14. RUNNERS-UP
--------------
Protected nodes (docs/design/protect-node.md, issue #1300): a flag that stops a parent
container from replacing or deleting a node through del, pop, assignment, merge and
unsafe_merge, while readonly keeps blocking writes through the node. Crosscuts
dictconfig/listconfig deletion and assignment, _map_merge and flag inheritance, but
the honest minimal estimate is 180-250 lines; viable only widened with an interacting
rule such as protection surviving OmegaConf.merge copies and select-time reporting.

Dotlist container syntax (docs/design/dotlist-container-syntax.md, Suspended):
OmegaConf.to_dotlist() plus container-preserving from_dotlist round-trip. A real
"missing direction" with a free round-trip oracle, but the maintainers suspended it
because the scope trends toward a serialization format, and the minimal work lands
mostly in one new function plus the value-quoting inverse of the grammar lexer
(G2/G5 risk).
