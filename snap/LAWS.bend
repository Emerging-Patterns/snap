# snap: the laws. The human states them; PROOF.bend must prove them.
import Base
import ./main.bend as Snap

# LAW: `cmd` is argv joined on newlines
law cmd_is_join:
  for argv: List<&2, String>
  {Snap.cmd(argv) == String.join(argv, "\n") : String}

# LAW: `line` is the same join as `cmd`
law line_is_cmd:
  for argv: List<&2, String>
  {Snap.line(argv) == Snap.cmd(argv) : String}

# LAW: no arguments join to the empty string
law cmd_nil:
  for u: Unit
  {Snap.cmd([]) == "" : String}

# LAW: one argument is that string
law cmd_one:
  for s: String
  {Snap.cmd(s <> Nil{}) == s : String}

# LAW: two arguments are joined with a newline
law cmd_two:
  for u: Unit
  {Snap.cmd(["echo", "hi"]) == "echo\nhi" : String}

# LAW: a job is the argument count, then `cmd`
law job_is_count_cmd:
  for argv: List<&2, String>
  {Snap.job(argv)
    == Nat.show(List.length(&2, String, argv)) ++ "\n" ++ Snap.cmd(argv)
    : String}

# LAW: an empty job is the count 0 and a trailing newline
law job_nil:
  for u: Unit
  {Snap.job([]) == "0\n" : String}

# LAW: one argument is the count 1 and that argument
law job_one:
  for u: Unit
  {Snap.job(["echo"]) == "1\necho" : String}

# LAW: two arguments keep their own lines
law job_two:
  for u: Unit
  {Snap.job(["echo", "hi"]) == "2\necho\nhi" : String}

# LAW: `plan` is the header fields, then every job
law plan_is_header:
  for js: List<&2, List<&2, String>>
  for +width: String
  for +gb: String
  for +at: String
  for +by: String
  {Snap.plan(js, width, gb, at, by)
    == String.join([width, gb, at, by], "\n") ++ Snap.plan.go(js)
    : String}

# LAW: no jobs is the header alone
law plan_nil:
  for u: Unit
  {Snap.plan([], "2", "1", "/tmp/out", "0") == "2\n1\n/tmp/out\n0" : String}

# LAW: one job follows the header
law plan_one:
  for u: Unit
  {Snap.plan([["echo", "hi"]], "2", "1", "/tmp/out", "0")
    == "2\n1\n/tmp/out\n0\n2\necho\nhi" : String}

# LAW: `code` is the first line of the answer
law code_is_first:
  for out: String
  {Snap.code(out) == Snap.code.of(String.lines(out)) : String}

# LAW: no lines is a program that could not be started
law code_none:
  for u: Unit
  {Snap.code.of([]) == "127" : String}

# LAW: an empty string is one empty line, so the status is empty
law code_empty:
  for u: Unit
  {Snap.code("") == "" : String}

# LAW: the status is the first line
law code_status:
  for u: Unit
  {Snap.code("0\nhello\n") == "0" : String}

# LAW: `text` is everything after the first line
law text_is_rest:
  for out: String
  {Snap.text(out) == Snap.text.of(String.lines(out)) : String}

# LAW: a missing body is the empty string
law text_empty:
  for u: Unit
  {Snap.text("") == "" : String}

# LAW: the body keeps the newline the program printed
law text_body:
  for u: Unit
  {Snap.text("0\nhello\n") == "hello\n" : String}

# LAW: `ok` is a status of 0
law ok_is_zero:
  for out: String
  {Snap.ok(out) == String.eq(Snap.code(out), "0") : Bool}

# LAW: status 0 is ok
law ok_zero:
  for u: Unit
  {Snap.ok("0\n") == True{} : Bool}

# LAW: a non-zero status is not ok
law ok_fail:
  for u: Unit
  {Snap.ok("1\n") == False{} : Bool}

# LAW: a job answer is the status, then the file's text
law par_of_is:
  for +code: String
  for m: Maybe<&2, String>
  {Snap.par.of(code, m) == code ++ "\n" ++ Snap.file.text_of(m) : String}

# LAW: a missing file is an empty body
law par_of_none:
  for u: Unit
  {Snap.par.of("0", None{}) == "0\n" : String}

# LAW: a file's text is those bytes
law file_text_of_some:
  for s: String
  {Snap.file.text_of(Some{s}) == s : String}

# LAW: nothing is the empty string
law file_text_of_none:
  for u: Unit
  {Snap.file.text_of(None{}) == "" : String}

# LAW: an empty list has no non-blank strings
law nonblank_nil:
  for u: Unit
  {Snap.par.nonblank([]) == [] : List<&2, String>}

# LAW: a blank string is dropped
law nonblank_drops:
  for u: Unit
  {Snap.par.nonblank(["0", "", "1"]) == ["0", "1"] : List<&2, String>}
