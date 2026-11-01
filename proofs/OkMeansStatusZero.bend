# proofs of laws/OkMeansStatusZero.bend
import Base
import ../src/answer.bend as Answer
import ../laws/CodeReadsStatus.bend as L1
import ../laws/OkMeansStatusZero.bend as Laws
import ./lemmas/StatusReading.bend as M1

def Laws.ok_reads_zero(s, b, h):
  Equal.cong(String, Bool, x => String.eq(x, "0"),
    Answer.code(s ++ "\n" ++ b), s, L1.code_reads_status(s, b, h))
