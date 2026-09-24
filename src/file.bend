# src/file: a file's text, read whole, or None when it cannot be opened.
import Base

# the handle closed, and whatever was gathered
def file.slurp.end(file: File, acc: String) -> IO(String):
  do IO<String>:
    File.close(file)
    return acc

# an empty chunk means the end of the file
def file.slurp.cut(chunk: String, file: File, acc: String, rest: File -> String -> IO(String)) -> IO(String):
  match chunk:
    case SNil{}:
      file.slurp.end(file, acc)
    case SCon{c, t}:
      rest(file, acc ++ SCon{c, t})

# a failed read ends the file as surely as an empty one
def file.slurp.more(
  res: Result<&1, &1, U32 & String, String>,
  file: File,
  acc: String,
  rest: File -> String -> IO(String)
) -> IO(String):
  match res:
    case Fail{_e}:
      file.slurp.end(file, acc)
    case Done{chunk}:
      file.slurp.cut(chunk, file, acc, rest)

# the handle comes back paired with what it read
def file.slurp.next(
  got: File & Result<&1, &1, U32 & String, String>,
  acc: String,
  rest: File -> String -> IO(String)
) -> IO(String):
  (file, res) = got
  file.slurp.more(res, file, acc, rest)

# the whole file, read in chunks until one is empty, or the fuel is
def file.slurp(fuel: Nat, file: File, acc: String) -> IO(String):
  match fuel:
    case 0n:
      file.slurp.end(file, acc)
    case 1n+f:
      do IO<String>:
        got : File & Result<&1, &1, U32 & String, String> <- File.read(file, 65536)
        file.slurp.next(got, acc, fl => a => file.slurp(f, fl, a))

# what an opened file holds, or nothing when it would not open
def file.read.opened(res: Result<&1, &1, U32 & String, File>) -> IO(Maybe<&2, String>):
  match res:
    case Fail{_e}:
      IO.pure(Maybe<&2, String>, None{})
    case Done{file}:
      do IO<Maybe<&2, String>>:
        text : String <- file.slurp(U32.to_nat(100000), file, "")
        return Some{text}

# a file's text, or None when it cannot be opened
def file.read(path: String) -> IO(Maybe<&2, String>):
  do IO<Maybe<&2, String>>:
    res : Result<&1, &1, U32 & String, File> <- File.open(path, "r")
    file.read.opened(res)

# a file's text, or "" when there is none
def file.text_of(got: Maybe<&2, String>) -> String:
  match got:
    case None{}:
      ""
    case Some{s}:
      s
