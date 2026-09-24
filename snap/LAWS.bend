# snap: the laws. The human states them; PROOF.bend must prove them. Each
# law that proves a SPEC.md requirement carries its ID (see SPEC.md).
import Base
import ./main.bend as Snap
import ../check/LAWS.bend as Str

# Reading an answer. An answer is a status on its own first line, then the
# body; the status holds no newline, and the body may hold anything.

# LAW: `code` reads back the status, whatever body follows it
# SNAP-ANS-1
law code_reads_status:
  for +s: String
  for +b: String
  for h: {Str.clear(s, '\n') == True{} : Bool}
  {Snap.code(s ++ "\n" ++ b) == s : String}

# LAW: `text` reads back the body, whatever it holds
# SNAP-ANS-2
law text_reads_body:
  for +s: String
  for +b: String
  for h: {Str.clear(s, '\n') == True{} : Bool}
  {Snap.text(s ++ "\n" ++ b) == b : String}

# LAW: `ok` is true exactly when the status is "0"
# SNAP-ANS-3
law ok_reads_zero:
  for +s: String
  for +b: String
  for h: {Str.clear(s, '\n') == True{} : Bool}
  {Snap.ok(s ++ "\n" ++ b) == String.eq(s, "0") : Bool}
