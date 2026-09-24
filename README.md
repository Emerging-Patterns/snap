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
either proved by a quantified law in `snap/LAWS.bend` (proofs in
`snap/PROOF.bend`, shared lemmas in `check/`) or named as a trusted
assumption about the C and JS effects that start programs. The reasoning is
in [docs/rfc/snap-spec.md](docs/rfc/snap-spec.md).

## Install

Use with [Bend](https://github.com/bendlang/bend) or install easily with [ez](https://github.com/Emerging-Patterns/ez):

```
ez init
ez add Emerging-Patterns/snap
```

## Usage

`run` answers with the exit status on its own first line, then stdout and
stderr together. `Snap.code` reads the status; `Snap.text` reads the body.

```
import 0x9bfd9d57916f3439316c2775fd1f10b4/main.bend as Snap

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
