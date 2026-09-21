# snap

Program runner for [Bend 2](https://github.com/bendlang/bend). Pass argv as a
list of strings — no shell — and get back exit status, stdout, and stderr.
`start` returns a pid without waiting; `par` runs several jobs together.
Helpers join argv and read answers. Laws and proofs live in `snap/LAWS.bend`
and `snap/PROOF.bend`.

## Install

Install Bend, then import the library from a program in this tree:

```
curl -fsSL https://bend-lang.com/install.sh | sh
```

```
import ./snap/main.bend as Snap
```

## Usage

`run` answers with the exit status on its own first line, then stdout and
stderr together. `Snap.code` reads the status; `Snap.text` reads the body.

```
import ./snap/main.bend as Snap

def main() -> IO(Unit):
  do IO<Unit>:
    +out : String <- Snap.run(["echo", "hello"])
    IO.print(Snap.code(out))
    IO.print(Snap.text(out))
```

```
git clone https://github.com/Emerging-Patterns/snap
cd snap
bend examples/demo/main.bend -o bin/demo.bin
bin/demo.bin
```
