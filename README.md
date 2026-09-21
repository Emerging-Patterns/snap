# snap

Process spawn / run-a-program for [Bend 2](https://github.com/bendlang/bend).
`run` (and `exec`) take argv as a list of strings, never a shell string, and
answer the exit status plus stdout and stderr. `start` leaves a program
running and answers its pid. `par` runs several programs at once. Helpers
`cmd`/`line`, `code`, `text`, and `ok` join argv and read an answer back.
`snap/LAWS.bend` states the helpers; `snap/PROOF.bend` proves those laws.

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

`nix build` builds the same fixture to `result/bin/demo`.
