# RFC: A Behavioral Specification for snap

Read at `be520aa` on `main` ("chore: bump Bend to 2.0.27 (#12)"), bend 2.0.27, package hub name `0x9bfd9d57916f3439316c2775fd1f10b4`.

## Draft Status

**State:** Accepted, and rolled out. The maintainer accepted every recommendation below on 2026-09-24, and each item is resolved in place. Every Proved row in SPEC.md is proved, and `trace` runs at error. REVIEW-10 is a repository setting a maintainer applies by hand; it is resolved as a decision and stays outstanding as an action until the ruleset exists.

This draft was written from the code at `be520aa`, from the evidence in the law inventory (`docs/rfc/snap-law-inventory.md`, folded into "Audit record" below when the rollout finished and deleted; read it whole at `cf1faba`), and from the positions reached by the specifications of ez ([ez-spec.md](https://github.com/Emerging-Patterns/ez/blob/master/docs/rfc/ez-spec.md)) and bolt ([bolt-spec.md](https://github.com/Emerging-Patterns/bolt/blob/main/docs/rfc/bolt-spec.md)), both of which depend on snap. Every verdict below was checked against the code, and most were confirmed by running a binary built from this tree on both of Bend's lanes. The items below are decisions this draft makes and asks a maintainer to confirm. Each one also appears inline where the decision lives. The first two come first because the rest depend on them.

**Items for review:**

- [x] <!-- REVIEW-1 (resolved): Accepted as recommended. snap takes ez's and bolt's positions unchanged: two levels, Proved and Trusted; a closed law has no standing; a test is never evidence. All 28 laws in snap/LAWS.bend are deleted in one change in phase one: the 18 whose only binder is an unused `for u: Unit` are closed laws in disguise, and the 10 others restate their def's body under `{==}`. bolt's `law` rule (L001) is set to warn in snap's bolt.bend until the phase two laws reach the pure defs again. We also ask bolt for `closed` to report a law whose binders the statement never uses, since both bolts we ran accept all 18. -->
- [x] <!-- REVIEW-2 (resolved): Accepted as recommended. The headline guarantee is SNAP-ARGV-1, the program receives exactly the argv it was given. Today an argument holding `\n` is split in two on every call. We propose that the wire the three effects read separates arguments with NUL instead of newline, since execve cannot pass a NUL inside an argument anyway, so NUL is the one separator that can never collide. `cmd` and `line` keep returning the newline join unchanged, because ez's `ez/pass.bend` hands `cmd`'s output to its own `pass.c`; the effects get a new `wire`. Behavior change for every caller whose arguments hold a newline, and a new hub name. -->
- [x] <!-- REVIEW-3 (resolved): Accepted as recommended. An argv that cannot be passed intact is refused before any effect runs: an empty argv, an empty program name, or any element holding NUL. `run` and `exec` answer `127\n`, the shape of a program that could not be started; `start` answers `0`; in `par` a refused job answers `127\n` in its own position and the other jobs are unaffected. Today native answers 127 for `[]` and `[""]`, and JS crashes the program. Behavior change on JS only, for inputs that crash today. -->
- [x] <!-- REVIEW-4 (resolved): Accepted as recommended. The JS lane's effects are brought in line with native, so the answer shape (SNAP-ANS-4) is one Trusted row for both lanes: a signal answers 128 plus its number (JS: 128); a `par` job ended by its deadline answers 124 (JS: 127); output over 1 MB is read whole (JS: status 127 from `maxBuffer`); a missing `par` directory answers 127 per job (JS: crash); stdout and stderr arrive interleaved in write order, by pointing both at one temporary file as `par.js` already does (JS: stdout then stderr). Behavior change on JS. -->
- [x] <!-- REVIEW-5 (resolved): Accepted as recommended. `start` on native answers `0` when the program could not be started, as JS already does, using a close-on-exec pipe the child writes to only when exec fails. Today it answers a pid for a program that does not exist. Behavior change on native. -->
- [x] <!-- REVIEW-6 (resolved): Accepted as recommended. `par`'s effect truncates `at/n` for every job it does not run (skipped by the deadline, refused), so no answer carries a previous run's output. Today a skipped job answered `124` with another run's body. Behavior change. -->
- [x] <!-- REVIEW-7 (resolved): Accepted as recommended. `code` and `text` read the answer up to and after its first newline directly instead of through `String.lines`, and the dead `"127"` arm of `code.of` goes. Every answer reads the same as before (the laws of SNAP-ANS state it), so this is a refactor, but it stops `code` walking the whole body, which is what overflows the JS interpreter on a 100 KB line. Whether `text` alone still overflows is measured in the PR. Landed: `text` returns the body without walking it, so neither reader walks the body, and the JS lane reads a 100 KB answer that overflowed it before. -->
- [x] <!-- REVIEW-8 (resolved): Accepted as recommended. The flake pins a bolt from before v0.4.0, which says `clean`; bolt v1.7.0 reports 19 errors. We propose bumping to the current bolt in the preliminary phase, fixing the S003 and S004 findings, marking the four IO entry points `# noqa: L001` as bolt did for its own (#191), and setting `law` to warn until phase two. `trace` goes on at warn in phase one and at error at the finish line. -->
- [x] <!-- REVIEW-9 (resolved): Accepted as recommended. The README's build fails on a fresh clone because `bin/` does not exist. We propose `mkdir -p bin` in the README and a flake check that follows the README literally, as ez's `readme` job does. -->
- [x] <!-- REVIEW-10 (resolved): Accepted as recommended. `main` has no branch protection. We propose a ruleset on `main` requiring the `ci` check and forbidding force pushes, applied by a maintainer by hand. SNAP-TRUST-4 holds only once it exists. -->
- [x] <!-- REVIEW-11 (resolved): Accepted as recommended. A file `par` cannot read partway through ends its body silently, and a body stops after 100000 chunks of 64 KiB. We propose no change: the cap is far past anything a job writes into a directory its caller owns, and a read error on a local file is outside what snap can report usefully. Both are recorded here and in the inventory rather than made requirements. -->

## Abstract

snap has 28 laws, every one proved by `{==}`. Eighteen pin one call on one input behind an unused `for u: Unit` binder, and ten restate the body of the def they name. So the proof gate passing tells us the helpers compute what their bodies say, and nothing about whether a program receives its arguments, whether the answer reads back, or whether `par` answers once per job, each of which we found broken for some input. This RFC defines a specification for snap in the shape of ez's and bolt's: every requirement is either **Proved** by a tagged quantified law or **Trusted** as a named assumption about the three foreign effects. It deletes every law snap has today, moves every decision snap makes (how argv is encoded, what is refused, how answers are assembled and read) into pure defs laws can reach, and names the effects' behavior as the trust boundary.

## Glossary

| Term | Meaning |
| :---- | :---- |
| ez, bolt | The project manager and the linter for Bend 2 (Emerging-Patterns/ez, Emerging-Patterns/bolt). Both import snap by its hub name, and both went through this process first. |
| argv | The program and its arguments as a `List<String>`, the program first. |
| Effect | One of the three foreign functions snap calls: `snaprun.exec`, `snaprun.start`, `snaprun.par`, each written twice, in C for the native lane and in JS for the interpreter. |
| Lane | Where a Bend program runs: native (compiled with `bend -o`, the C effects) or JS (`bend file.bend`, the JS effects). |
| Wire | The one string an effect receives. Today it is argv joined on newlines (`cmd`), or for `par` the header fields and counted jobs (`plan`). |
| Answer | The string `run` returns: the status on its own first line, then the body. |
| Status | The first line of an answer: the exit status, 128 plus the signal, 124 for a deadline, 127 for a program that could not start. |
| Body | Everything after the first line of an answer: what the program printed on stdout and stderr. |
| Refused | An argv the planner will not hand to an effect, because the wire could not carry it intact. |
| Planner | The pure part of a call: from its arguments, the wire to hand the effect, or a refusal. |
| Closed law | A law with no binder, or whose binders the statement never uses. It holds for one input. |
| Quantified law | A law whose statement depends on at least one binder. |
| Proof gate | For every PROOF.bend, `bend PROOF.bend` prints exactly `All terms check.` as its first line. |
| Proved | A requirement backed by a quantified law tagged with its ID, passing the proof gate. |
| Trusted | A requirement that is assumed, listed in the trust boundary, and checked by nothing in snap. |
| Pending | The status of a Proved requirement whose law has not landed. It is a status, not a level. |

## Background

### What snap is

snap runs programs for Bend 2 without a shell. `run` (and its alias `exec`) waits for a program and answers its status and output; `start` leaves one running and answers its pid; `par` runs several at once, with a width, a memory cap per job, an output directory and a deadline. `code`, `text` and `ok` read an answer. Each effect has a C and a JS implementation, and the Bend side is a few pure helpers around them.

### Who depends on it

ez calls `exec` 167 times, `text` 70, `ok` 55, and `code`, `par`, `start` and `cmd` a few times each; bolt calls `exec`, `code` and `text`. Both pin `0x9bfd9d57…`, the name of the tree at `be520aa`. ez also reuses `cmd` as the wire of its own effect, `ez/pass.bend`, which splits it on newlines in its own C and JS. So any change to snap's files is a new hub name that reaches ez and bolt only when they bump, and a change to what `cmd` returns is a change to `ez run`.

### How snap proves things today

The inventory counts 28 laws, 18 closed in disguise and 10 definitional, all `{==}`. None reaches an effect, and none states a property a refactor could break without also changing the line the law copies.

## Problem Statement

Every behavior of snap should answer two questions: is it guaranteed, and if so, is it proved or assumed? Today neither has an answer. The one promise the README leads with, that argv is passed as given with no shell, is broken for an argument holding a newline, and nothing in the gate could notice.

Goals: a SPEC.md in bolt's format where every row is Proved or Trusted; every decision snap makes in Bend, reachable by a law; the effects' behavior stated as narrow Trusted rows, the same on both lanes; `trace` at error.

Non-goals: proving anything about the C or JS code; changing `run`'s answer shape; a new API. ez's `pass` effect has the same newline bug, which is ez's to fix (Future Steps).

## Proposal

### Two levels, and the positions carried over

We take ez's and bolt's positions unchanged. Exactly two levels, Proved and Trusted. A closed law has no standing, and a law whose only binder is unused counts as closed. A test is never evidence for a requirement. Laws only reach values, so every decision that can be made in Bend is made in Bend.

<!-- REVIEW-1 (resolved): Accepted as recommended. snap takes ez's and bolt's positions unchanged: two levels, Proved and Trusted; a closed law has no standing; a test is never evidence. All 28 laws in snap/LAWS.bend are deleted in one change in phase one: the 18 whose only binder is an unused `for u: Unit` are closed laws in disguise, and the 10 others restate their def's body under `{==}`. bolt's `law` rule (L001) is set to warn in snap's bolt.bend until the phase two laws reach the pure defs again. We also ask bolt for `closed` to report a law whose binders the statement never uses, since both bolts we ran accept all 18. -->

### The headline guarantee

The row whose failure would make snap pointless is SNAP-ARGV-1: the program receives exactly the argv it was given. It is what "no shell" is for. Stating it forces the question of what the wire can carry, and today the answer is "anything but a newline", with nothing refusing the rest.

<!-- REVIEW-2 (resolved): Accepted as recommended. The headline guarantee is SNAP-ARGV-1, the program receives exactly the argv it was given. Today an argument holding `\n` is split in two on every call. We propose that the wire the three effects read separates arguments with NUL instead of newline, since execve cannot pass a NUL inside an argument anyway, so NUL is the one separator that can never collide. `cmd` and `line` keep returning the newline join unchanged, because ez's `ez/pass.bend` hands `cmd`'s output to its own `pass.c`; the effects get a new `wire`. Behavior change for every caller whose arguments hold a newline, and a new hub name. -->

We considered three encodings. Refusing any argument that holds a newline keeps the C unchanged but makes a multi-line argument impossible (a commit message, a script for `sh -c`; ez writes each of its `sh -c` scripts on one line today, `ez/say.bend`, which the newline split forces on it). Escaping newlines needs an unescaper in each of six effect files, each a new place to diverge. A NUL separator needs only the split character changed, and its one refusal, an argument holding NUL, is an argument no program could receive anyway. The spike in phase three confirms that a Bend string holding NUL reaches `io_cstr` and `split("\0")` whole on both lanes before the change lands.

### The planner, the wire and the effects

|  |
|:---:|
| <pre>argv ──▶ run.plan ──▶ Refused ──▶ "127\n"&#10;                  └──▶ Run{wire} ──▶ snaprun.exec (C / JS) ──▶ answer ──▶ code / text / ok</pre> |
| Caption: every decision is in `run.plan` and the readers, where laws apply. The effect splits the wire and runs it; that it splits exactly as `wire.split` does is Trusted. |

The Bend side gains, as proposed names:

- `wire(argv)`: argv joined on NUL. `wire.split(s)`: the model of how the effects split it, in Bend, used only by laws.
- `accepts(argv) -> Bool`: argv is not empty, its first element is not empty, and no element holds NUL.
- `run.plan(argv)`: `Run{wire(argv)}` when accepted, `Refused{}` otherwise. `run` performs the plan; a refusal answers `127\n` without calling the effect. `start` does the same with `0`. As built, `run` is `run.with(snaprun.exec, run.plan(argv))`: the effect is a parameter of the pure `run.with`, so the frame law quantifies over every effect and says a refused plan answers the same whichever one it was given, and no law has to reach the foreign code itself.
- For `par`, `par.plan` builds the header and the jobs with each refused job replaced by an empty job (count `0`), and `plan.split` models how the effect parses it. The effect answers 127 for an empty job and keeps walking.
- `par.answers(statuses, bodies)`: the pure assembly `par.read` does today inside IO, so SNAP-PAR-2 can be stated. `par.read` becomes the reads, then one call to it.

<!-- REVIEW-3 (resolved): Accepted as recommended. An argv that cannot be passed intact is refused before any effect runs: an empty argv, an empty program name, or any element holding NUL. `run` and `exec` answer `127\n`, the shape of a program that could not be started; `start` answers `0`; in `par` a refused job answers `127\n` in its own position and the other jobs are unaffected. Today native answers 127 for `[]` and `[""]`, and JS crashes the program. Behavior change on JS only, for inputs that crash today. -->

### Requirements

Verdicts are the inventory's. A row whose verdict is partly or fails states the decided behavior and depends on the change named.

#### Arguments (SNAP-ARGV)

| ID | Requirement | Level | Status | Verdict | Evidence |
| :---- | :---- | :---- | :---- | :---- | :---- |
| SNAP-ARGV-1 | For every argv that `accepts`, `wire.split(wire(argv))` is exactly argv. | Proved | pending | fails (depends on REVIEW-2) | an argument holding `\n` splits in two today, both lanes |
| SNAP-ARGV-2 | `run.plan(argv)` is `Refused{}` exactly when argv is empty, its first element is empty, or an element holds NUL; a refused `run` or `exec` answers `127\n` and a refused `start` answers `0`, and neither calls an effect. | Proved | pending | partly (depends on REVIEW-3) | native 127 for `[]`, `[""]`; JS crashes |
| SNAP-ARGV-3 | Each effect executes the argv it splits from its wire directly, with no shell, resolving the program on `PATH`. | Trusted | | holds | `execvp`, `spawnSync` and `spawn` without `shell` |

Law sketches, in SNAP-ARGV-1's words: `for argv, h: {accepts(argv) == True{} : Bool}` then `{wire.split(wire(argv)) == argv : List<String>}`, by induction on argv with a lemma that splitting `a ++ "\0" ++ s` for a NUL-free `a` conses `a` onto the split of `s`. SNAP-ARGV-2 is a direct law in each direction over `run.plan`, plus the frame law that a refused plan calls no effect, which holds when `run` matches on the plan before any IO.

#### Answers (SNAP-ANS)

| ID | Requirement | Level | Status | Verdict | Evidence |
| :---- | :---- | :---- | :---- | :---- | :---- |
| SNAP-ANS-1 | For every status `s` holding no newline and every body `b`, `code(s ++ "\n" ++ b)` is `s`. | Proved | pending | holds | `code.of(String.lines(out))` |
| SNAP-ANS-2 | For every status `s` holding no newline and every body `b`, `text(s ++ "\n" ++ b)` is `b`. | Proved | pending | holds | `String.join` inverts `String.split` on one separator |
| SNAP-ANS-3 | For every status `s` holding no newline and every body `b`, `ok(s ++ "\n" ++ b)` is true exactly when `s` is `"0"`. | Proved | pending | holds | `main.bend:200-201` |
| SNAP-ANS-4 | On both lanes, `snaprun.exec` answers one line holding the program's exit status, or 128 plus the signal that ended it, or 127 when it could not be started, then every byte the program wrote to stdout and stderr, in the order written; the program's stdin is empty. | Trusted | | partly (depends on REVIEW-4) | JS: 128 for a signal, stdout before stderr, 127 above 1 MB |

These laws have real content: `code` and `text` never see the effect, so the law is about every string of that shape, and the proof needs the split and join lemma in both directions. The laws hold unchanged through REVIEW-7's refactor, which is the point of stating them before it.

<!-- REVIEW-7 (resolved): Accepted as recommended. `code` and `text` read the answer up to and after its first newline directly instead of through `String.lines`, and the dead `"127"` arm of `code.of` goes. Every answer reads the same as before (the laws of SNAP-ANS state it), so this is a refactor, but it stops `code` walking the whole body, which is what overflows the JS interpreter on a 100 KB line. Whether `text` alone still overflows is measured in the PR. Landed: `text` returns the body without walking it, so neither reader walks the body, and the JS lane reads a 100 KB answer that overflowed it before. -->

#### Start (SNAP-START)

| ID | Requirement | Level | Status | Verdict | Evidence |
| :---- | :---- | :---- | :---- | :---- | :---- |
| SNAP-START-1 | On both lanes, `snaprun.start` answers the pid of a child running the argv in a session of its own with `/dev/null` for all three streams, without waiting for it, or `0` when the program could not be started. | Trusted | | partly (depends on REVIEW-5) | native answers a pid for a missing program |

<!-- REVIEW-5 (resolved): Accepted as recommended. `start` on native answers `0` when the program could not be started, as JS already does, using a close-on-exec pipe the child writes to only when exec fails. Today it answers a pid for a program that does not exist. Behavior change on native. -->

#### Parallel runs (SNAP-PAR)

| ID | Requirement | Level | Status | Verdict | Evidence |
| :---- | :---- | :---- | :---- | :---- | :---- |
| SNAP-PAR-1 | For every job list and every header whose fields hold no NUL, `plan.split(par.plan(js, width, gb, at, by))` is exactly the header and one job per job of `js`, in order, each the job's argv when it `accepts` and the empty job otherwise. | Proved | pending | fails (depends on REVIEW-2, REVIEW-3) | an empty job, or a newline in an argument, drops every later job |
| SNAP-PAR-2 | For every list of statuses and every list of bodies, `par.answers` has exactly one answer per status, and the answer at position `n` is status `n`, a newline, then body `n`, or the empty string when there is no body `n`. | Proved | pending | partly | `par.read` pairs by position inside IO today |
| SNAP-PAR-3 | On both lanes, `snaprun.par` answers exactly one status per job of its wire, in order, each as `snaprun.exec` would for that job; 127 for the empty job; 124 for a job skipped because the deadline had passed or ended by it; and it writes each job's output to `at/n` and truncates `at/n` for every job it does not run. | Trusted | | partly (depends on REVIEW-4, REVIEW-6) | JS: 127 on timeout, crash on a missing `at`; both: stale file for a skipped job |
| SNAP-PAR-4 | `snaprun.par` runs at most `width` jobs at once; an empty or zero width is the online cores, reduced to what the spare memory holds at `gb` each, and at least 1. | Trusted | | holds on native | `par.c:69-80`; JS runs one at a time |

SNAP-PAR-2 with SNAP-PAR-3 gives the property callers need, `par` answers once per job in order, with the effect's half named as an assumption and the assembly proved. SNAP-PAR-1's law is induction on the jobs with ARGV-1's lemma per job and one for the count.

<!-- REVIEW-6 (resolved): Accepted as recommended. `par`'s effect truncates `at/n` for every job it does not run (skipped by the deadline, refused), so no answer carries a previous run's output. Today a skipped job answered `124` with another run's body. Behavior change. -->

### Retiring the laws snap has

All 28 go in phase one, in the change that lands SPEC.md. None proves a row, so nothing is tagged first. The inventory's "points toward" column keeps the map. `cmd`, `line`, `job` and `plan` lose their laws until phase three reaches them, which is why `law` is at warn in between.

### Tagging and traceability

SPEC.md uses bolt's format exactly, since bolt's `trace` rule reads it: requirement tables headed `| ID | Requirement | Level | Status | Law |`, the Law cell as `<path> <law>` entries joined by `; `, a trust table headed `| ID | Assumption | Why it is trusted |`, and each tag a `# <ID>` line alone in the comment block directly above its `law`. A pending row may name tagged laws that prove part of it, with a "Left to prove" section saying what is missing.

### Refactoring contract

A change to snap must keep every tagged law passing the proof gate without editing its statement in LAWS.bend. Proofs may be rewritten; untagged laws may change. A requirement moves from Proved to Trusted only as a reviewed behavior change, and a PR that adds a Trusted row justifies it. Since any byte changed is a new hub name, the PR description says whether the change is a behavior change for ez and bolt when they bump.

### Trust boundary

| ID | Assumption | Why it is trusted |
| :---- | :---- | :---- |
| SNAP-TRUST-1 | The Bend checker is sound. | It cannot be checked from inside Bend; this is EZ-TRUST-1. snap pins bend 2.0.27 through the flake. |
| SNAP-TRUST-2 | The proof gate runner runs bend on every PROOF.bend and accepts only an exact `All terms check.` first line. | It is ez's `mkProofs`, run by `nix flake check`. |
| SNAP-TRUST-3 | Each effect, C and JS, splits its wire exactly as `wire.split` and `plan.split` do. | Foreign code; it is the interpreter's faithfulness, and each split is a few lines, reviewed line by line. |
| SNAP-TRUST-4 | Every commit on `main` passed `ci.yml`. | Holds only once the ruleset in REVIEW-10 exists. Today it does not hold. |
| SNAP-ARGV-3 | Each effect executes its argv with no shell. | Foreign code calling `execvp` and node's `child_process`. |
| SNAP-ANS-4 | `snaprun.exec`'s answer shape. | Foreign code and the kernel's report of how a child ended. |
| SNAP-START-1 | `snaprun.start`'s pid or `0`. | Foreign code. |
| SNAP-PAR-3 | `snaprun.par`'s statuses, output files and deadline. | Foreign code, the clock and the kernel. |
| SNAP-PAR-4 | `snaprun.par`'s width. | Foreign code reading cores and `/proc/meminfo`. |

<!-- REVIEW-10 (resolved): Accepted as recommended. `main` has no branch protection. We propose a ruleset on `main` requiring the `ci` check and forbidding force pushes, applied by a maintainer by hand. SNAP-TRUST-4 holds only once it exists. -->

The effect rows are most of snap's behavior, and they stay Trusted: no Bend law can see a child process. What moves out of them is every decision the effects used to make on the Bend side's behalf, what the wire holds, what is refused, how answers pair with jobs, so what is left trusted is a split, an exec and a report.

### Decided behavior changes

Each lands as its own PR, with the cases run against a binary built from `main` and one from the branch, on both lanes, and a row stays pending until the change it depends on lands. Each is a new hub name.

- From REVIEW-2: the effects split on NUL; `wire` is added; `cmd` and `line` are unchanged.
- From REVIEW-3: `run`, `exec`, `start` and `par` refuse through their planners; the effects answer 127 for an empty job and keep walking.
- From REVIEW-4: the JS effects report signals, deadlines and large output as native does, catch a missing directory, and interleave stdout and stderr through one file.
- From REVIEW-5: native `start` answers `0` for a program that could not start.
- From REVIEW-6: `par`'s effects truncate the file of every job they do not run.
- From REVIEW-8 and REVIEW-9: the bolt bump and lint fixes, and the README's `mkdir -p bin` with a check that follows it. Neither changes snap's behavior.

<!-- REVIEW-4 (resolved): Accepted as recommended. The JS lane's effects are brought in line with native, so the answer shape (SNAP-ANS-4) is one Trusted row for both lanes: a signal answers 128 plus its number (JS: 128); a `par` job ended by its deadline answers 124 (JS: 127); output over 1 MB is read whole (JS: status 127 from `maxBuffer`); a missing `par` directory answers 127 per job (JS: crash); stdout and stderr arrive interleaved in write order, by pointing both at one temporary file as `par.js` already does (JS: stdout then stderr). Behavior change on JS. -->

<!-- REVIEW-8 (resolved): Accepted as recommended. The flake pins a bolt from before v0.4.0, which says `clean`; bolt v1.7.0 reports 19 errors. We propose bumping to the current bolt in the preliminary phase, fixing the S003 and S004 findings, marking the four IO entry points `# noqa: L001` as bolt did for its own (#191), and setting `law` to warn until phase two. `trace` goes on at warn in phase one and at error at the finish line. -->

<!-- REVIEW-9 (resolved): Accepted as recommended. The README's build fails on a fresh clone because `bin/` does not exist. We propose `mkdir -p bin` in the README and a flake check that follows the README literally, as ez's `readme` job does. -->

<!-- REVIEW-11 (resolved): Accepted as recommended. A file `par` cannot read partway through ends its body silently, and a body stops after 100000 chunks of 64 KiB. We propose no change: the cap is far past anything a job writes into a directory its caller owns, and a read error on a local file is outside what snap can report usefully. Both are recorded here and in the inventory rather than made requirements. -->

### How we will know it worked

No row is pending; `trace` and `law` are at error on the current bolt; snap/LAWS.bend holds no law whose binders go unused; and a rewrite of `main.bend`'s pure defs, `code` and `text` in REVIEW-7 being the first, is mergeable on the proof gate alone.

## Abandoned Ideas

### Keep the closed laws until the real ones land

They would keep `law` at error through the rollout. But they state one input each, several pin wording nobody depends on (`cmd_two`, `plan_one`), and `code_none` pins an arm no caller reaches, so they would point the next author at the wrong behavior. ez and bolt both ended by deleting theirs at once.

### Tests of the effects as evidence

A test that runs `echo` through each effect on each lane would catch a regression in the C or JS. It is still an example: it says nothing about the input next to it, and the lane divergences above would each have passed a plausible test. The effects' behavior is Trusted, and snap's demo stays a host check outside the specification.

### Refuse newlines instead of changing the separator

Smaller, since the effects would not change. It makes a multi-line argument impossible to pass at all, which is the constraint ez already works around by writing its `sh -c` scripts on one line. It is rejected under REVIEW-2 in favor of a separator no argument can hold.

### Model the effects in Bend and prove them equal to C

The model would share whatever misreading the C has, which is the refactor-equivalence pattern ez and bolt deleted. SNAP-TRUST-3 names the one place a model is used, the split, and keeps it small enough to review.

## Rollout

| Phase | What lands | What it leaves true |
| :---- | :---- | :---- |
| Preliminary | the ruleset on `main` (REVIEW-10); the bolt bump and lint fixes (REVIEW-8); the README fix and its check (REVIEW-9) | the lint gate checks current rules; the README builds |
| One | SPEC.md with every row pending or Trusted; all 28 laws deleted; `trace` at warn | SPEC.md honest: nothing is proved, and it says so |
| Two | SNAP-ANS-1 to 3 proved, then REVIEW-7's refactor merged on the gate | the readers proved, the first refactor made on the gate alone |
| Three | the spike (NUL across `io_cstr` and JS on both lanes); `wire`, `accepts`, `run.plan`; REVIEW-2 and REVIEW-3; SNAP-ARGV-1 and 2 proved; REVIEW-5 | the headline guarantee proved |
| Four | `par.plan`, `plan.split`, `par.answers`; REVIEW-6; SNAP-PAR-1 and 2 proved | every Proved row proved; `trace` and `law` at error |

REVIEW-4 lands whenever it is ready, since it changes only Trusted rows.

## Risks

- **The NUL wire may not survive a lane.** If a Bend string holding NUL does not reach `io_cstr` or the JS effect whole, the phase three spike says so before any change lands, and REVIEW-2 falls back to escaping.
- **String lemmas cost more than expected.** SNAP-ANS and SNAP-ARGV-1 need split and join inverse lemmas over `String`. ez's `check/str.bend` has neighbors of them; we reuse before we write.
- **Downstream breakage.** Every behavior change is a new hub name, so nothing breaks until ez and bolt bump, and when they do, the changes are ones their callers should want. `cmd` is kept unchanged for ez's `pass`.
- **The trust boundary is most of snap.** That is honest, not a failure: what a child process does is outside Bend. The risk is that a Trusted row hides a decision that could move into Bend, which is what every REVIEW item above looked for.

## Future Steps

- ez's `pass` effect splits `cmd` on newlines and has the same bug as SNAP-ARGV-1. Once snap's `wire` lands, ez can hand `pass` the NUL wire, or snap can offer `pass` itself.
- A `par` that answers each job with its own identity rather than its position would let SNAP-PAR-2 drop its dependence on the effect answering in order.

## Audit record

The law inventory was the progress tracker for this RFC. When the rollout finished it was folded into this section and deleted; the full document, with the per-law table and the verdict table, is `docs/rfc/snap-law-inventory.md` at `cf1faba`.

### What snap proved before

At `be520aa` snap had 28 laws. Every one of the 28 proofs is `{==}`. The 18 `U` laws each pin one call on one input. The 10 `Q` laws each restate the body of the def they name: `cmd` is `String.join(argv, "\n")`, `code` is `code.of(String.lines(out))`, and so on. None of them states a property of snap that a refactor could break without also changing the line the law copies.

What snap proves today: nothing about running a program. The laws show that the pure helpers compute what their bodies say. They say nothing about whether the program receives the arguments it was given, whether `code` and `text` read back what the effect wrote, or whether `par` answers once per job, and we found each of those broken for some input (below). The three effects, where everything that matters happens, are foreign C and JS code that no law reaches and no SPEC.md names.

### What each call read

This table is as read at `be520aa`. Since the rollout, every decision in it that Bend can make is made in `run.plan`, `par.plan` and `par.answers`, and the reads that remain are the effects' own.

| Call | Input | Where | Decision it feeds |
| :---- | :---- | :---- | :---- |
| `run`, `exec` | argv, through the wire | `exec.c:13-32`, `exec.js:5` | what is executed |
| | `PATH` | `execvp`, `spawnSync` | which file is executed |
| | the child's exit status or signal | `exec.c:62-64`, `exec.js:7` | the status line |
| | the child's stdout and stderr | `exec.c:52-59`, `exec.js:8` | the body |
| `start` | argv, `PATH` | `start.c:13-44`, `start.js:7-9` | what is started |
| | the fork's result | `start.c:33`, `start.js:11` | the pid answered |
| `par` | the header fields and jobs, through the wire | `par.c:94-143`, `par.js:11-23` | what runs, how many at once, where output goes, the deadline |
| | the clock | `par.c:158`, `par.js:24` | whether a job is skipped, and its alarm |
| | `/proc/meminfo`, `sysinfo`, online cores | `par.c:46-80` | the width when none is given |
| | each child's status | `par.c:193-215` | the job's status |
| | the files `at/0` … `at/n-1` | `main.bend:154-162` | each job's body, including files this run did not write |

Places a failed or missing read becomes a default: a file that cannot be opened becomes an empty body (`file.read`, `main.bend:124`); a read error partway through a file ends it silently with what was read (`file.slurp.more`, `main.bend:88-94`); the slurp stops silently after 100000 chunks of 64 KiB (`main.bend:120`); `atoi` turns a malformed count into 0, which ends the job walk (`par.c:125`).

### Findings

Each finding is marked "Confirmed" (run on the named lane) or "by reading". Every bug below is fixed by the rollout, and the rollout record says where.

#### Behavior the code guarantees that no requirement mentions

- `code`, `text` and `ok` are total and read any string, not only an effect's answer. By reading.
- `text(s ++ "\n" ++ b)` is `b` for every `b`, including one with trailing newlines, because `String.split` and `String.join` on the same separator are inverse. This is the reader's real guarantee and has no law. By reading.
- `cmd` is also a wire format a downstream project depends on: ez's `ez/pass.bend` hands `R.cmd(argv)` to its own `pass.c`, which splits on newlines. Changing what `cmd` returns changes ez's `ez run`. By reading ez at `df6d616`.
- The package's hub name changes with any byte of its seven files, so every change below reaches ez and bolt only when they bump their pin.

#### Behavior that looks accidental

- `code.of([])` answers `"127"`, but `code` never passes it `[]`; `code("")` is `""`. The `code_none` law pins an arm nothing reaches. By reading `String.split` in bend 2.0.27's `base.bend`.
- `line` and `exec` are aliases of `cmd` and `run`. By reading.
- Native's `run` interleaves stdout and stderr in write order; JS appends stderr after stdout. Confirmed.
- `par` on the JS lane runs its jobs one at a time. Documented in `par.js`. By reading.
- Invalid UTF-8 in a program's output reaches Bend as U+FFFD on both lanes. Confirmed.
- On `main`, native also split an argument at a NUL (`["printf", "[%s]", "a\0b"]` printed `[a][b]`), since the split walked the whole buffer for terminators; JS threw `ERR_INVALID_ARG_VALUE`. Confirmed while checking phase three against `main`; `accepts` now refuses such an argv.
- On `main`, native `run` dropped an empty last argument: `["sh", "-c", "echo $#", "sh", "a", ""]` printed 1 natively and 2 on JS, because the split never recorded a field after the final separator. Confirmed; fixed in phase four for all three C effects.
- The children of `run` inherit every descriptor the parent holds open that is not close-on-exec. By reading `exec.c`.

#### Requirements with no corresponding code

- Nothing refuses an argv that cannot be passed intact (an argument holding `\n` or NUL, or no program name). The wire silently changes it.
- Nothing ties a `par` answer to its job other than position, and nothing checks that the count of answers equals the count of jobs.

#### Bugs

- An argument holding `\n` is split into two arguments by `run`, `exec`, `start` and `par`. Confirmed.
- `par` drops an empty job and every job after it, and an argument holding `\n` drops every later job. Confirmed.
- `par` answers a skipped job with a previous run's output. Confirmed.
- The JS lane crashes the whole program on `run([])`, `run([""])`, and on `par` when `at` does not exist. Confirmed.
- The JS lane reports a killed program as 128 (native: 128 plus the signal), a `par` job ended by its deadline as 127 (native: 124), and a successful program that printed over 1 MB as 127. Confirmed.
- `start` on native answers a pid for a program that could not be started. Confirmed.
- On the JS lane, `code` and `text` overflow the interpreter's stack on an answer with a line of about 100 KB, because both walk the whole answer through `String.lines` even though `code` needs only the first line. Confirmed.
- The README's build step `bend examples/demo/main.bend -o bin/demo.bin` fails on a fresh clone, because `bin/` is ignored and does not exist (`/usr/bin/ld: cannot open output file`), and bend exits 1. Confirmed. This is the same bug ez's README had.
- The flake pins a bolt from before v0.4.0, so the lint gate in CI checks rules two major versions out of date and cannot run `trace`. Confirmed.
- `main` has no branch protection (`protected: false` from the GitHub API on 2026-09-24; rulesets not checked), so the gate binds nothing.

### Rollout record

| Phase | Item | State | What landed |
| :---- | :---- | :---- | :---- |
| Preliminary | REVIEW-9, README build | done | `mkdir -p bin` in the README; a `readme` CI job follows it without nix, then runs the proof gate by its first line |
| Preliminary | REVIEW-8, bolt bump | done | bolt pinned at v1.7.0 (`38da7d9`), following snap's ez; S002, S003 and S004 fixed; `# noqa: L001` on `run`, `exec`, `start`, `par` and the demo's IO defs; the demo's `nth` replaced by an IO walk with the same output; bolt v1.7.0 says `clean` with every group at error |
| Preliminary | REVIEW-10, ruleset on `main` | waiting on a maintainer | a repository setting, applied by hand |
| One | SPEC.md, the 28 laws deleted, `trace` at warn | done | SPEC.md with 7 Proved rows pending and 5 Trusted; all 28 laws and their proofs deleted, leaving `snap/LAWS.bend` and `PROOF.bend` as headers so the IO entry points stay under law; `laws` at warn for `coverage`, `closed` and `unsafe` at error, `trace` at warn. bolt: 0 errors, 7 coverage warnings on `cmd`, `line`, `job`, `plan`, `code`, `text`, `ok`. `trace` checked by planting a tag for an unknown ID (reported) and for a pending row (accepted) |
| Two | SNAP-ANS-1 to 3 | done | `code_reads_status`, `text_reads_body`, `ok_reads_zero` (direct laws, all tagged) over `code`, `text` and `ok` unchanged; the string lemmas they rest on (`split_front`, `split_sep`, `join_split`, `append_nil`, and `char_eq_true` beneath them) copied from ez into `check/LAWS.bend` and `check/PROOF.bend`, 37 laws, untagged. Each proof fails when replaced by `{==}`, and each of four planted bugs (`code` trims the answer, `code` reads the body, `text` joins without newlines, `ok` tests for `"1"`) fails in its own law's proof. Coverage warnings: 4 (`cmd`, `line`, `job`, `plan`) |
| Two | REVIEW-7, `code` and `text` without `String.lines` | done | `code` reads up to the first newline and `text` returns what follows it as it stands, each through a helper that takes the recursive call as a thunk; `code.of` and `text.of`, with the dead `"127"` arm, are gone. Merged on the gate: the three tagged statements are unchanged, only the proofs were rewritten (induction on the status). Old and new readers agree on 11 edge inputs on both lanes; the JS lane now reads a 100 KB answer (it overflowed before) |
| Three | REVIEW-2, REVIEW-3, REVIEW-5; SNAP-ARGV-1 and 2 | done | The spike first: a NUL-joined wire carried a newline inside an argument, an empty argument and non-ASCII text through `io_cstr` and `split("\0")` whole on both lanes. Then `wire`, `accepts`, `free_of`, the `Step` plan and `run.plan`; `run`, `exec` and `start` perform the plan through `run.with` and `start.with`, which take the effect as a parameter so the frame laws can say a refused plan answers the same whatever the effect; `exec` and `start` effects split on NUL; native `start` reads a close-on-exec pipe and answers 0 when exec fails. Laws: `wire_round_trip` (SNAP-ARGV-1); `refuses_empty`, `refuses_no_program`, `refuses_nul`, `runs_accepted`, `refused_run_calls_nothing`, `refused_start_calls_nothing` (SNAP-ARGV-2, the last two frame laws). `split_join` added to `check/` from ez. Every new proof fails as `{==}`; five planted bugs each fail the gate, and `isolate_mutant.py` shows `refuses_nul` and `refuses_no_program` each catch their bug with the earlier laws set aside. Against `main`'s snap on both lanes: a newline in an argument now arrives whole (was split), NUL in an argument is refused with 127 (native split it in two, JS crashed), `start` of a missing program answers 0 on native (was a pid); empty argv, an empty program name, a missing program and `echo` answer as before |
| Four | `par`: REVIEW-6, SNAP-PAR-1 and 2; `trace` and `laws` at error | done | The `par` wire is NUL-separated fields: the header, then each job's arguments marked with `+` and an empty field that ends the job, so no count has to be parsed and a refused job is the empty job in its own place. `par.plan` builds it; `par.answers` pairs statuses with bodies purely, and `par.bodies` only reads the files. The C and JS effects read the new fields, answer 127 for the empty job, and empty the file of every job they do not run. A field after the last NUL is now read in all three C effects: the old loop dropped an empty last field, so `run(["printf", "%s", ""])` lost its empty argument. Laws: `par_plan_round_trip` (SNAP-PAR-1, through the law-side model `plan.split`); `par_answers_codes`, `par_answers_texts`, `par_statuses_read_back` (SNAP-PAR-2); `cmd_round_trip` and `line_round_trip`, untagged, for ez's `pass` wire. Every new proof fails as `{==}`; six planted bugs each fail the gate, and `isolate_mutant.py` shows the order and body bugs caught by their own laws. Against `main` on both lanes: an empty job no longer drops the jobs after it; a newline in an argument arrives whole (JS dropped the next job; native aborted the program with `munmap_chunk(): invalid pointer`); a skipped job's body is empty, not a previous run's. Every Proved row is proved; bolt says `clean` with every rule at error, `trace` included, and removing one tag fails it |
| After | REVIEW-4, the JS lane's statuses | done | `exec.js` points stdout and stderr at one temporary file, as `exec.c` points them at one pipe, so output arrives in write order and without spawnSync's 1 MB cap, and maps a signal to 128 plus its number; `par.js` answers 124 for a job its deadline ended, 128 plus the signal for any other signal, and 127 per job when `at` does not exist. On the branch both lanes now answer the same for: `kill -9` (137), stderr and stdout interleaved, 1.1 MB of output (status 0, all bytes), a missing program (127), `exit 3`, `par` with a killed job (137) and a missing directory (127), and `par`'s deadline (124 for the job it ended and the one it skipped). SNAP-ANS-4 and SNAP-PAR-3 now hold as written on both lanes, by these checks |
