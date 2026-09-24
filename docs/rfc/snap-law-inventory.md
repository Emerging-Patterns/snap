# snap law inventory

Read at `be520aa` on `main` ("chore: bump Bend to 2.0.27 (#12)"), with bend 2.0.27 (the release archive `flake.lock` pins through `bendlang/bend` at `d379091`, checksum matching the flake's `58adc86a…`). The package at this commit hashes to `0x9bfd9d57916f3439316c2775fd1f10b4`, the name the README imports and the name ez and bolt pin.

This is the companion to [snap-spec.md](snap-spec.md). It records what `snap/LAWS.bend` states today, maps each law to the requirement it points toward, and records what we found by reading the code and running it. It follows the shape of ez's and bolt's inventories, and it takes the positions their specifications reached: exactly two assurance levels, Proved and Trusted; pending is a status, not a level; a closed law has no standing; a test is never evidence for a requirement.

## How to read the tables

**Kind** is `Q` for a quantified law whose binder the statement uses, `C` for a closed law (no binder), and `U` for a law whose only binder is `for u: Unit` and never appears in the statement. A `U` law passes bolt's `closed` rule, but it states one fixed input, so it is a closed law in disguise and is counted with the closed ones.

**Proof** is `{==}` when the whole proof in PROOF.bend is `{==}`, and `struct` when it matches, recurses or rewrites. For a `Q` law, `{==}` means the binders are never inspected, so the law restates how a definition unfolds.

**Claim** is what the law states, in one line, about the input it is really about.

**Points toward** names the requirement in the RFC the law illustrates, or `none` with a reason: `definitional` restates a definition, `wiring` restates how two defs compose, `wording` pins a fixed output nobody decided to guarantee, `dead arm` pins a branch no caller can reach.

## The gate and bolt on snap

The proof gate is `bend PROOF.bend` from `snap/`, and its first line must be exactly `All terms check.`. We ran it with the pinned bend. We linted the tree with two bolts built from source: the one `flake.lock` pins (`24b497e`, which `git describe` places before v0.4.0), and the current release, v1.7.0, whose dependencies we filled with ez's `bootstrap.sh` because the hub is not reachable from the audit machine.

| Check | First line of output | Exit | Time |
| :---- | :---- | ----: | ----: |
| `bend snap/PROOF.bend` | `All terms check.` | 0 | 0.5 s |
| pinned bolt (`24b497e`) over the tree | `clean` | 0 | under 1 s |
| bolt v1.7.0 over the tree | 19 errors | 1 | under 1 s |

bolt v1.7.0 reports six S003 findings (a wrapped def header without one parameter per line, `snap/main.bend` lines 64, 79, 88, 97, 113 and 169), six S004 findings (a one-letter parameter: `r`, `m`, `i` in `snap/main.bend`, `n` in the demo), and seven L001 findings (no quantified law reaches `run`, `exec`, `start`, `par`, and the demo's `show`, `nth` and `main`). Neither bolt reports any of the 18 `U` laws, because each has a binder. The pinned bolt has no `trace` rule, so nothing today could check a SPEC.md.

The pinned bolt says `clean` because it predates the S003, S004 and stricter L001 rules, not because the tree meets the current rules. This is the same finding bolt's inventory made about its own self-lint.

## Summary

| File | Laws | `Q` | `U` | `C` | `Q` proved by `{==}` |
| :---- | ----: | ----: | ----: | ----: | ----: |
| `snap/LAWS.bend` | 28 | 10 | 18 | 0 | 10 |

Every one of the 28 proofs is `{==}`. The 18 `U` laws each pin one call on one input. The 10 `Q` laws each restate the body of the def they name: `cmd` is `String.join(argv, "\n")`, `code` is `code.of(String.lines(out))`, and so on. None of them states a property of snap that a refactor could break without also changing the line the law copies.

What snap proves today: nothing about running a program. The laws show that the pure helpers compute what their bodies say. They say nothing about whether the program receives the arguments it was given, whether `code` and `text` read back what the effect wrote, or whether `par` answers once per job, and we found each of those broken for some input (below). The three effects, where everything that matters happens, are foreign C and JS code that no law reaches and no SPEC.md names.

## Inventory

| Law | Kind | Proof | Claim | Points toward |
| :---- | :---- | :---- | :---- | :---- |
| `cmd_is_join` | Q | `{==}` | `cmd(argv)` is `String.join(argv, "\n")` | none (definitional); SNAP-ARGV-1 needs a round trip instead |
| `line_is_cmd` | Q | `{==}` | `line` is `cmd` | none (definitional) |
| `cmd_nil` | U | `{==}` | `cmd([])` is `""` | SNAP-ARGV-2 (the collision with `[""]`) |
| `cmd_one` | Q | `{==}` | `cmd([s])` is `s` | none (definitional) |
| `cmd_two` | U | `{==}` | `cmd(["echo", "hi"])` is `"echo\nhi"` | none (wording) |
| `job_is_count_cmd` | Q | `{==}` | `job(argv)` is the count, a newline, then `cmd(argv)` | none (definitional); SNAP-PAR-1 needs a round trip instead |
| `job_nil` | U | `{==}` | `job([])` is `"0\n"` | SNAP-PAR-1 (the empty job) |
| `job_one` | U | `{==}` | `job(["echo"])` is `"1\necho"` | none (wording) |
| `job_two` | U | `{==}` | `job(["echo", "hi"])` is `"2\necho\nhi"` | none (wording) |
| `plan_is_header` | Q | `{==}` | `plan` is the four header fields joined, then `plan.go(js)` | none (definitional) |
| `plan_nil` | U | `{==}` | `plan([], "2", "1", "/tmp/out", "0")` is the header alone | none (wording) |
| `plan_one` | U | `{==}` | one fixed job after one fixed header | none (wording) |
| `code_is_first` | Q | `{==}` | `code(out)` is `code.of(String.lines(out))` | none (wiring); SNAP-ANS-1 |
| `code_none` | U | `{==}` | `code.of([])` is `"127"` | none (dead arm: `String.lines` never returns `[]`) |
| `code_empty` | U | `{==}` | `code("")` is `""` | none (wording) |
| `code_status` | U | `{==}` | `code("0\nhello\n")` is `"0"` | SNAP-ANS-1 |
| `text_is_rest` | Q | `{==}` | `text(out)` is `text.of(String.lines(out))` | none (wiring); SNAP-ANS-2 |
| `text_empty` | U | `{==}` | `text("")` is `""` | none (wording) |
| `text_body` | U | `{==}` | `text("0\nhello\n")` is `"hello\n"` | SNAP-ANS-2 |
| `ok_is_zero` | Q | `{==}` | `ok(out)` is `String.eq(code(out), "0")` | none (definitional); SNAP-ANS-3 |
| `ok_zero` | U | `{==}` | `ok("0\n")` is true | SNAP-ANS-3 |
| `ok_fail` | U | `{==}` | `ok("1\n")` is false | SNAP-ANS-3 |
| `par_of_is` | Q | `{==}` | `par.of(code, m)` is `code ++ "\n" ++ file.text_of(m)` | none (definitional); SNAP-PAR-2 |
| `par_of_none` | U | `{==}` | `par.of("0", None{})` is `"0\n"` | SNAP-PAR-2 |
| `file_text_of_some` | Q | `{==}` | `file.text_of(Some{s})` is `s` | none (definitional) |
| `file_text_of_none` | U | `{==}` | `file.text_of(None{})` is `""` | none (definitional) |
| `nonblank_nil` | U | `{==}` | `par.nonblank([])` is `[]` | none (wording) |
| `nonblank_drops` | U | `{==}` | `par.nonblank(["0", "", "1"])` is `["0", "1"]` | SNAP-PAR-2 |

## Coverage by requirement

The requirement IDs are the RFC's. No law proves any of them today.

| ID | Laws that point toward it | Proved today |
| :---- | :---- | :---- |
| SNAP-ARGV-1 | none (`cmd_is_join` restates the join, and says nothing about the split) | no |
| SNAP-ARGV-2 | `cmd_nil` | no |
| SNAP-ANS-1 | `code_is_first`, `code_status` | no |
| SNAP-ANS-2 | `text_is_rest`, `text_body` | no |
| SNAP-ANS-3 | `ok_is_zero`, `ok_zero`, `ok_fail` | no |
| SNAP-PAR-1 | `job_nil` | no |
| SNAP-PAR-2 | `par_of_is`, `par_of_none`, `nonblank_drops` | no |
| Trusted rows | none, as expected | not applicable |

## Requirements against code

The verdicts use the README's promises and the header comments in `snap/main.bend` and the effects as the draft requirements, since snap has no SPEC.md. "Confirmed" means we ran it on the named lane with a probe built from this tree; "by reading" means we did not.

| ID | Draft requirement | Verdict | Evidence |
| :---- | :---- | :---- | :---- |
| SNAP-ARGV-1 | The program receives exactly the argv it was given, one argument per list element. | partly | An argument holding `\n` is split in two: `run(["printf", "%s\|", "x\ny"])` prints `x\|y\|` on both lanes. `cmd` joins on `\n` (`main.bend:31`) and `exec.c:18-31`, `exec.js:5` split on it. Confirmed. |
| SNAP-ARGV-2 | An argv that names no program is not run. | partly | `cmd([])` and `cmd([""])` are both `""`. Native answers 127 for both (execvp of `""` fails). The JS lane throws `ERR_INVALID_ARG_VALUE` out of `spawnSync` (`exec.js:6`), which is not caught, and the whole program exits 1. Confirmed. |
| SNAP-ARGV-3 | No shell sees the arguments. | holds | `execvp` (`exec.c:48`, `start.c:43`, `par.c:183`), `spawnSync`/`spawn` without `shell` (`exec.js:6`, `start.js:9`, `par.js:32`). By reading, and `printf` receiving `%s\|` unexpanded is consistent with it. |
| SNAP-ANS-1 | `code` reads the status the effect wrote on the first line. | holds | `code.of(String.lines(out))` takes the first line (`main.bend:176-193`), and the effect's status line never holds a newline. By reading; the law needs a split/join lemma. |
| SNAP-ANS-2 | `text` reads back exactly what the program printed. | holds on native, partly on JS | `text.of` joins the lines after the first with `\n` (`main.bend:184-197`), which inverts `String.split`. On the JS lane, reading any answer with a line of about 100 KB overflows the interpreter's stack inside `String.lines` (`bend: memory fault`); 20 KB works, and the compiled binary reads 1.1 MB. Confirmed. |
| SNAP-ANS-3 | `ok` is true exactly when the status is 0. | holds | `main.bend:200-201`. By reading. |
| SNAP-ANS-4 | The answer's status is the exit status, 128 plus the signal for a killed program, 127 for one that could not start, and the body is stdout and stderr together. | partly | Native: status 3, 137 for `kill -9`, 127 for a missing program, and stdout and stderr interleaved in write order through one pipe (`exec.c:44-45`). JS: 128 for `kill -9` (`exec.js:7` ignores `r.signal`), stdout then stderr (`exec.js:8`), and 127 for a successful program that printed more than 1 MB (`spawnSync`'s default `maxBuffer` sets `r.error` to `ENOBUFS`). Confirmed on both lanes; the 1 MB case confirmed with node directly, since the interpreter overflows first. |
| SNAP-START-1 | `start` answers the pid of the running program, or `0` when it could not be started. | partly | Native answers a pid for a program that does not exist (`start.c:33-48`: the fork succeeds, the exec fails in the child). JS answers `0` (`start.js:11`, `child.pid` is undefined). Confirmed. |
| SNAP-PAR-1 | `par` runs exactly the jobs it was given, each with its argv. | partly | A job `[]` (`job` writes `"0\n"`) stops the effect's walk (`par.c:126`, `par.js:19`), so it and every later job are dropped: three jobs answer once. An argument holding `\n` shifts the count framing, so the next job's count is read from an argument and the walk stops. Confirmed on both lanes. |
| SNAP-PAR-2 | `par` answers once per job, in the order given, each in `run`'s shape. | partly | Holds when PAR-1 holds. When the walk stops early the answers are fewer than the jobs, and nothing tells the caller which job an answer belongs to beyond its position. Confirmed. |
| SNAP-PAR-3 | A job not started by the deadline answers 124, and one the deadline ends answers 124. | partly | Native: both 124. JS: a job the timeout ends answers 127 (`par.js:34` tests `r.error` before `r.status`, and a timeout sets `r.error` to `ETIMEDOUT`). A skipped job's file is never written, so `par.read` reads whatever a previous run left in `at/n`: a skipped job answered `124` with the body `stale`. Confirmed on both lanes. |
| SNAP-PAR-4 | A job whose output file cannot be opened answers 127. | partly | Native: 127 (`par.c:170-173`). JS: `fs.openSync` throws outside the `try` (`par.js:30`), and the whole program exits. Confirmed. |
| SNAP-PAR-5 | At most `width` jobs run at once; an empty width is worked out from cores and spare memory. | holds on native | `par.c:69-80`, `155`. JS runs one job at a time (`par.js:4-7`), which is within any width. By reading. |

## What each call reads

snap is a library, so the World of each call is what its effect observes. Every read below is in foreign code.

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

## Findings

### Behavior the code guarantees that no requirement mentions

- `code`, `text` and `ok` are total and read any string, not only an effect's answer. By reading.
- `text(s ++ "\n" ++ b)` is `b` for every `b`, including one with trailing newlines, because `String.split` and `String.join` on the same separator are inverse. This is the reader's real guarantee and has no law. By reading.
- `cmd` is also a wire format a downstream project depends on: ez's `ez/pass.bend` hands `R.cmd(argv)` to its own `pass.c`, which splits on newlines. Changing what `cmd` returns changes ez's `ez run`. By reading ez at `df6d616`.
- The package's hub name changes with any byte of its seven files, so every change below reaches ez and bolt only when they bump their pin.

### Behavior that looks accidental

- `code.of([])` answers `"127"`, but `code` never passes it `[]`; `code("")` is `""`. The `code_none` law pins an arm nothing reaches. By reading `String.split` in bend 2.0.27's `base.bend`.
- `line` and `exec` are aliases of `cmd` and `run`. By reading.
- Native's `run` interleaves stdout and stderr in write order; JS appends stderr after stdout. Confirmed.
- `par` on the JS lane runs its jobs one at a time. Documented in `par.js`. By reading.
- Invalid UTF-8 in a program's output reaches Bend as U+FFFD on both lanes. Confirmed.
- On `main`, native also split an argument at a NUL (`["printf", "[%s]", "a\0b"]` printed `[a][b]`), since the split walked the whole buffer for terminators; JS threw `ERR_INVALID_ARG_VALUE`. Confirmed while checking phase three against `main`; `accepts` now refuses such an argv.
- The children of `run` inherit every descriptor the parent holds open that is not close-on-exec. By reading `exec.c`.

### Requirements with no corresponding code

- Nothing refuses an argv that cannot be passed intact (an argument holding `\n` or NUL, or no program name). The wire silently changes it.
- Nothing ties a `par` answer to its job other than position, and nothing checks that the count of answers equals the count of jobs.

### Bugs

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

## Rollout progress

| Phase | Item | State | What landed |
| :---- | :---- | :---- | :---- |
| Preliminary | REVIEW-9, README build | done | `mkdir -p bin` in the README; a `readme` CI job follows it without nix, then runs the proof gate by its first line |
| Preliminary | REVIEW-8, bolt bump | done | bolt pinned at v1.7.0 (`38da7d9`), following snap's ez; S002, S003 and S004 fixed; `# noqa: L001` on `run`, `exec`, `start`, `par` and the demo's IO defs; the demo's `nth` replaced by an IO walk with the same output; bolt v1.7.0 says `clean` with every group at error |
| Preliminary | REVIEW-10, ruleset on `main` | waiting on a maintainer | a repository setting, applied by hand |
| One | SPEC.md, the 28 laws deleted, `trace` at warn | done | SPEC.md with 7 Proved rows pending and 5 Trusted; all 28 laws and their proofs deleted, leaving `snap/LAWS.bend` and `PROOF.bend` as headers so the IO entry points stay under law; `laws` at warn for `coverage`, `closed` and `unsafe` at error, `trace` at warn. bolt: 0 errors, 7 coverage warnings on `cmd`, `line`, `job`, `plan`, `code`, `text`, `ok`. `trace` checked by planting a tag for an unknown ID (reported) and for a pending row (accepted) |
| Two | SNAP-ANS-1 to 3 | done | `code_reads_status`, `text_reads_body`, `ok_reads_zero` (direct laws, all tagged) over `code`, `text` and `ok` unchanged; the string lemmas they rest on (`split_front`, `split_sep`, `join_split`, `append_nil`, and `char_eq_true` beneath them) copied from ez into `check/LAWS.bend` and `check/PROOF.bend`, 37 laws, untagged. Each proof fails when replaced by `{==}`, and each of four planted bugs (`code` trims the answer, `code` reads the body, `text` joins without newlines, `ok` tests for `"1"`) fails in its own law's proof. Coverage warnings: 4 (`cmd`, `line`, `job`, `plan`) |
| Two | REVIEW-7, `code` and `text` without `String.lines` | done | `code` reads up to the first newline and `text` returns what follows it as it stands, each through a helper that takes the recursive call as a thunk; `code.of` and `text.of`, with the dead `"127"` arm, are gone. Merged on the gate: the three tagged statements are unchanged, only the proofs were rewritten (induction on the status). Old and new readers agree on 11 edge inputs on both lanes; the JS lane now reads a 100 KB answer (it overflowed before) |
| Three | REVIEW-2, REVIEW-3, REVIEW-5; SNAP-ARGV-1 and 2 | done | The spike first: a NUL-joined wire carried a newline inside an argument, an empty argument and non-ASCII text through `io_cstr` and `split("\0")` whole on both lanes. Then `wire`, `accepts`, `free_of`, the `Step` plan and `run.plan`; `run`, `exec` and `start` perform the plan through `run.with` and `start.with`, which take the effect as a parameter so the frame laws can say a refused plan answers the same whatever the effect; `exec` and `start` effects split on NUL; native `start` reads a close-on-exec pipe and answers 0 when exec fails. Laws: `wire_round_trip` (SNAP-ARGV-1); `refuses_empty`, `refuses_no_program`, `refuses_nul`, `runs_accepted`, `refused_run_calls_nothing`, `refused_start_calls_nothing` (SNAP-ARGV-2, the last two frame laws). `split_join` added to `check/` from ez. Every new proof fails as `{==}`; five planted bugs each fail the gate, and `isolate_mutant.py` shows `refuses_nul` and `refuses_no_program` each catch their bug with the earlier laws set aside. Against `main`'s snap on both lanes: a newline in an argument now arrives whole (was split), NUL in an argument is refused with 127 (native split it in two, JS crashed), `start` of a missing program answers 0 on native (was a pid); empty argv, an empty program name, a missing program and `echo` answer as before |
| Four | `par`: REVIEW-6, SNAP-PAR-1 and 2 | next | |
