# snap

Program runner for [Bend 2](https://github.com/bendlang/bend). Pass argv as a
list of strings — no shell — and get back exit status, stdout, and stderr.
`start` returns a pid without waiting; `par` runs several jobs together.
Helpers join argv and read answers.

Every argument reaches the program whole, newlines and all. An argv that
could not arrive whole, one with no program name or with NUL inside an
argument, is refused: `run` answers status 127 and `start` answers 0, and
nothing is run. In `par`, a refused job answers 127 in its own place.

What snap guarantees is listed in [SPEC.md](SPEC.md): each requirement is
either proved by a quantified law in `LAWS.bend` (proofs in
`PROOF.bend`, shared lemmas in `check/`) or named as a trusted
assumption about the C and JS effects that start programs. The reasoning is
in [docs/rfc/snap-spec.md](docs/rfc/snap-spec.md).

## Install

With [Bend](https://github.com/bendlang/bend) alone there is nothing to
install: import snap by its hub name and `bend` fetches it from
[the hub](https://hub.bend-lang.com) into `~/.bend/lib` on the first run.
`0x103d0af04de36ab98b311e537366ec67` is snap v1.0.0.

```
import 0x103d0af04de36ab98b311e537366ec67/main.bend as Snap
```

Or with [ez](https://github.com/Emerging-Patterns/ez), which records the
package in `ez.toml` (`ez init` makes one):

```
ez add Emerging-Patterns/snap
```

## Usage

`run` answers with the exit status on its own first line, then stdout and
stderr together. `Snap.code` reads the status; `Snap.text` reads the body.

```
import 0x103d0af04de36ab98b311e537366ec67/main.bend as Snap

def main() -> IO(Unit):
  do IO<Unit>:
    +out : String <- Snap.run(["echo", "hello"])
    IO.print(Snap.code(out))
    IO.print(Snap.text(out))
```

```
git clone https://github.com/Emerging-Patterns/snap
cd snap
mkdir -p bin
bend examples/demo/main.bend -o bin/demo.bin
bin/demo.bin
```
