# snap specification

This is the list of every behavior snap guarantees, each under a stable requirement ID. Every requirement has one of two levels. A **Proved** requirement holds for every input, and is backed by a quantified law in a LAWS.bend that passes the proof gate. A **Trusted** requirement is an assumption about something snap cannot check from inside its own gate, most of all the three foreign effects that start programs, and it is listed in the trust boundary below. A Proved requirement whose law has not landed yet has status **pending**: we intend to prove it, and until then it is not guaranteed. The proof gate is this check: for every PROOF.bend in the tree, the first line `bend PROOF.bend` prints is exactly `All terms check.` CI runs it in the `proofs` flake check and in the `readme` job.

The reasoning behind each requirement, and the decisions that shaped them, are in [docs/rfc/snap-spec.md](docs/rfc/snap-spec.md). What snap proved before this list existed, and what we found, is in [docs/rfc/snap-law-inventory.md](docs/rfc/snap-law-inventory.md).

## Tagging

A quantified law that proves a requirement carries the requirement's ID in a comment directly above its `law` line:

```
# SNAP-ANS-1
law code_reads_status:
```

A law with no binder claims one computed case and no requirement, so snap has none. bolt's `closed` rule (L002), on at `error` through the `laws` group settings in `bolt.bend`, rejects any law in a LAWS.bend without a `for` or `exs` binder. A law whose only binder its statement never uses is closed as well; bolt cannot see that yet, so review does.

A pending requirement may already have tagged quantified laws that prove part of it. The Law column names them, and "Left to prove" below says what is missing before the status becomes proved.

The Law column lists `<path> <law>` entries, the path relative to this file, joined by `; `. bolt's `trace` rule (L005) reads this file and checks it against the tags: every law a Proved row names must exist, have a binder and carry the row's ID; a proved row must name at least one; a Trusted row names none and has a row in the trust boundary; and no law may carry an ID that is not a Proved row here. `trace` is at `error` in `bolt.bend`.

Untagged quantified laws are allowed. They pass the proof gate like any law, but nothing here protects them, so a change may edit or delete them freely.

## Requirements

### Arguments (SNAP-ARGV)

| ID | Requirement | Level | Status | Law |
| :---- | :---- | :---- | :---- | :---- |
| SNAP-ARGV-1 | For every argv that `accepts`, `wire.split(wire(argv))` is exactly argv: the effects receive every argument whole, whatever characters other than NUL it holds. | Proved | proved | snap/LAWS.bend wire_round_trip |
| SNAP-ARGV-2 | `run.plan(argv)` is `Refused{}` exactly when argv is empty, its first element is empty, or an element holds NUL. A refused `run` or `exec` answers `127\n` and a refused `start` answers `0`, whatever effect they were given, so neither calls one. | Proved | proved | snap/LAWS.bend refuses_empty; snap/LAWS.bend refuses_no_program; snap/LAWS.bend refuses_nul; snap/LAWS.bend runs_accepted; snap/LAWS.bend refused_run_calls_nothing; snap/LAWS.bend refused_start_calls_nothing |
| SNAP-ARGV-3 | Each effect executes the argv it splits from its wire directly, with no shell, resolving the program on `PATH`. | Trusted | | |

### Answers (SNAP-ANS)

| ID | Requirement | Level | Status | Law |
| :---- | :---- | :---- | :---- | :---- |
| SNAP-ANS-1 | For every status `s` holding no newline and every body `b`, `code(s ++ "\n" ++ b)` is `s`. | Proved | proved | snap/LAWS.bend code_reads_status |
| SNAP-ANS-2 | For every status `s` holding no newline and every body `b`, `text(s ++ "\n" ++ b)` is `b`. | Proved | proved | snap/LAWS.bend text_reads_body |
| SNAP-ANS-3 | For every status `s` holding no newline and every body `b`, `ok(s ++ "\n" ++ b)` is true exactly when `s` is `"0"`. | Proved | proved | snap/LAWS.bend ok_reads_zero |
| SNAP-ANS-4 | On both lanes, `snaprun.exec` answers one line holding the program's exit status, or 128 plus the signal that ended it, or 127 when it could not be started, then every byte the program wrote to stdout and stderr, in the order written; the program's stdin is empty. | Trusted | | |

### Start (SNAP-START)

| ID | Requirement | Level | Status | Law |
| :---- | :---- | :---- | :---- | :---- |
| SNAP-START-1 | On both lanes, `snaprun.start` answers the pid of a child running the argv in a session of its own with `/dev/null` for all three streams, without waiting for it, or `0` when the program could not be started. | Trusted | | |

### Parallel runs (SNAP-PAR)

| ID | Requirement | Level | Status | Law |
| :---- | :---- | :---- | :---- | :---- |
| SNAP-PAR-1 | For every job list and every header whose fields hold no NUL, `plan.split(par.plan(js, width, gb, at, by))` is exactly the header and one job per job of `js`, in order, each the job's argv when it `accepts` and the empty job otherwise. | Proved | proved | snap/LAWS.bend par_plan_round_trip |
| SNAP-PAR-2 | For every list of statuses and every list of bodies, `par.answers` has exactly one answer per status, and the answer at position `n` reads back status `n` and body `n`, or the empty body when there is no body `n`; and the statuses the effect answers, one to a line, each holding a char and no newline, are read back exactly. | Proved | proved | snap/LAWS.bend par_answers_codes; snap/LAWS.bend par_answers_texts; snap/LAWS.bend par_statuses_read_back |
| SNAP-PAR-3 | On both lanes, `snaprun.par` answers exactly one status per job of its wire, in order, each as `snaprun.exec` would for that job; 127 for the empty job; 124 for a job skipped because the deadline had passed or ended by it; and it writes each job's output to `at/n` and truncates `at/n` for every job it does not run. | Trusted | | |
| SNAP-PAR-4 | `snaprun.par` runs at most `width` jobs at once; an empty or zero width is the online cores, reduced to what the spare memory holds at `gb` each, and at least 1. | Trusted | | |

## Left to prove

No requirement is pending. The Trusted row SNAP-ANS-4 does not yet hold as written on the JS lane, which reports a signal as 128, reads at most 1 MB of output, and puts stderr after stdout; the decided change REVIEW-4 in [docs/rfc/snap-spec.md](docs/rfc/snap-spec.md) makes it hold, and SNAP-PAR-3 with it for the JS lane's deadline status and a missing directory.

## Trust boundary

| ID | Assumption | Why it is trusted |
| :---- | :---- | :---- |
| SNAP-TRUST-1 | The Bend checker is sound. | It cannot be checked from inside Bend; this is EZ-TRUST-1. snap pins bend 2.0.27 through the flake. |
| SNAP-TRUST-2 | The proof gate runner runs bend on every PROOF.bend and accepts only an exact `All terms check.` first line. | It is ez's `mkProofs` in the `proofs` flake check, and a shell loop in the `readme` CI job. |
| SNAP-TRUST-3 | Each effect, C and JS, reads every wire the planners make exactly as `wire.split` and `plan.split` in snap/LAWS.bend do. | Foreign code; it is the effects' faithfulness to the planner, and each split is a few lines reviewed line by line. |
| SNAP-TRUST-4 | Every commit on `main` passed `ci.yml`. | Holds only once a maintainer adds the ruleset in REVIEW-10. Today it does not hold. |
| SNAP-ARGV-3 | Each effect executes its argv with no shell. | Foreign code calling `execvp` and node's `child_process`. |
| SNAP-ANS-4 | `snaprun.exec`'s answer shape. | Foreign code and the kernel's report of how a child ended. |
| SNAP-START-1 | `snaprun.start`'s pid or `0`. | Foreign code. |
| SNAP-PAR-3 | `snaprun.par`'s statuses, output files and deadline. | Foreign code, the clock and the kernel. |
| SNAP-PAR-4 | `snaprun.par`'s width. | Foreign code reading cores and `/proc/meminfo`. |
