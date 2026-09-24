# examples/demo: a fixture that runs programs through snap
import Base
import ../../main.bend as Snap

# one run as `label code=... text=...`
def show(+label: String, +out: String) -> IO(Unit):  # noqa: L001 demo output
  IO.print(label ++ " code=" ++ Snap.code(out) ++ " text=" ++ Snap.text(out))

# every batch answer, labeled `par<n>` by its place in the order
def show.par(rs: List<&2, String>, +nn: Nat) -> IO(Unit):
  match rs:
    case Nil{}:
      IO.pure(Unit, Unit{})
    case Con{+h, t}:
      do IO<Unit>:
        show("par" ++ Nat.show(nn), h)
        show.par(t, (1n + nn : Nat))

# the directory text, without its trailing newline
def dir.of(+out: String) -> String:
  String.trim(Snap.text(out))

def main() -> IO(Unit):  # noqa: L001 demo entry point
  do IO<Unit>:
    +hi : String <- Snap.run(["echo", "hello"])
    show("run", hi)
    +also : String <- Snap.exec(["echo", "also"])
    show("exec", also)
    +pid : String <- Snap.start(["true"])
    IO.print("start pid=" ++ pid)
    +tmp : String <- Snap.run(["mktemp", "-d"])
    +at : String <- IO.pure(String, dir.of(tmp))
    +rs : List<&2, String> <- Snap.par([["echo", "a"], ["echo", "b"]], "2", "1",
      at, "0")
    show.par(rs, 0n)
