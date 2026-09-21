# examples/demo: a fixture that runs programs through snap
import Base
import ../../snap/main.bend as Snap

# one run as `label code=... text=...`
def show(+label: String, +out: String) -> IO(Unit):
  IO.print(label ++ " code=" ++ Snap.code(out) ++ " text=" ++ Snap.text(out))

# the nth answer, or ""
def nth(rs: List<&2, String>, n: Nat) -> String:
  match rs n:
    case Nil{} _m:
      ""
    case Con{h, _t} 0n:
      h
    case Con{_h, t} 1n+p:
      nth(t, p)

# two batch answers labeled
def show.par(+rs: List<&2, String>) -> IO(Unit):
  do IO<Unit>:
    show("par0", nth(rs, 0n))
    show("par1", nth(rs, 1n))

# the directory text, without its trailing newline
def dir.of(+out: String) -> String:
  String.trim(Snap.text(out))

def main() -> IO(Unit):
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
    show.par(rs)
