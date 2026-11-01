# snap's laws. Each guarantee is one file under laws/, its prose on top and
# its quantified laws under it, proved by the file of the same name under
# proofs/; LAWS.bend and PROOF.bend only import them. The gate: the first
# line `bend PROOF.bend` prints is exactly `ALL PROOFS CHECK`. CI runs it in
# the `proofs` flake check and in the `readme` job. Tests and the demo are
# never evidence for a guarantee; what snap cannot prove, most of all the
# three foreign effects that start programs, is said where it is assumed, on
# the code (src/effect.bend, main.bend).
#
# An answer is a status on its own first line, then the body; the status
# holds no newline, and the body may hold anything. A wire is what a planner
# hands an effect: `wire(argv)` for `run`, `exec` and `start`, the
# arguments joined at NUL, and `par.plan` for `par`.
#
# The gate is PROOF.bend, not the entry: bend's verdict fails any file whose
# imports hold foreign code, so `bend main.bend --check-only` prints
# `SOME PROOFS FAIL`, naming the effects and the defs that call them, and
# that is expected. For the same reason no law file imports main.bend: the
# answer laws are stated over src/answer.bend and the `cmd` and `line` laws
# over src/argv.bend, whose defs main.bend's `code`, `text`, `ok`, `cmd` and
# `line` return unchanged (trusted in main.bend).
#
# Some laws state string and comparison facts the proofs need and Base does
# not: that a comparison which answered equal was given one thing twice
# (laws/StringEqTrue.bend), and that cutting a string at a separator and
# joining the pieces back gives it back (laws/SplitJoin.bend,
# laws/JoinSplit.bend). They were copied from ez's check/eq.bend and
# check/str.bend at df6d616 (Emerging-Patterns/ez), which proved them first,
# keeping only what snap's proofs use; snap has no dependency on ez, so they
# live here.
#
# The reasoning behind each guarantee is in docs/rfc/snap-spec.md. It names
# the guarantees by the requirement IDs of docs/SPEC.md, the table these
# files replaced.
import Base
import ./laws/AndLeft.bend as AndLeft
import ./laws/AndRight.bend as AndRight
import ./laws/AppendAssoc.bend as AppendAssoc
import ./laws/AppendNil.bend as AppendNil
import ./laws/BoolCmpSelf.bend as BoolCmpSelf
import ./laws/BoolEq.bend as BoolEq
import ./laws/CharCmpSelf.bend as CharCmpSelf
import ./laws/CharEqSelf.bend as CharEqSelf
import ./laws/CharEqTrue.bend as CharEqTrue
import ./laws/CmdSplitsBackAtNewlines.bend as CmdSplitsBackAtNewlines
import ./laws/CmpIsEq.bend as CmpIsEq
import ./laws/CodeReadsStatus.bend as CodeReadsStatus
import ./laws/EqFinRec.bend as EqFinRec
import ./laws/EqHead.bend as EqHead
import ./laws/EqHeadCmp.bend as EqHeadCmp
import ./laws/EqOfCmp.bend as EqOfCmp
import ./laws/EqTail.bend as EqTail
import ./laws/EqTailCmp.bend as EqTailCmp
import ./laws/FinCons.bend as FinCons
import ./laws/FinHead.bend as FinHead
import ./laws/FinTail.bend as FinTail
import ./laws/JoinGoCons.bend as JoinGoCons
import ./laws/JoinSplit.bend as JoinSplit
import ./laws/JoinSplitArm.bend as JoinSplitArm
import ./laws/JoinSplitCons.bend as JoinSplitCons
import ./laws/LineSplitsBackAtNewlines.bend as LineSplitsBackAtNewlines
import ./laws/NotTrue.bend as NotTrue
import ./laws/OkMeansStatusZero.bend as OkMeansStatusZero
import ./laws/OrderGoGt.bend as OrderGoGt
import ./laws/OrderGoLt.bend as OrderGoLt
import ./laws/ParAnswersPairStatusWithBody.bend as ParAnswersPairStatusWithBody
import ./laws/ParWireKeepsEveryJob.bend as ParWireKeepsEveryJob
import ./laws/PushCons.bend as PushCons
import ./laws/RefusedArgvCallsNoEffect.bend as RefusedArgvCallsNoEffect
import ./laws/SplitCons.bend as SplitCons
import ./laws/SplitFront.bend as SplitFront
import ./laws/SplitJoin.bend as SplitJoin
import ./laws/SplitJoinGo.bend as SplitJoinGo
import ./laws/SplitOne.bend as SplitOne
import ./laws/SplitSep.bend as SplitSep
import ./laws/StartsAppend.bend as StartsAppend
import ./laws/StartsNil.bend as StartsNil
import ./laws/StringCmpSelf.bend as StringCmpSelf
import ./laws/StringEqSelf.bend as StringEqSelf
import ./laws/StringEqTrue.bend as StringEqTrue
import ./laws/TextReadsBody.bend as TextReadsBody
import ./laws/U32CmpSelf.bend as U32CmpSelf
import ./laws/U32Eq.bend as U32Eq
import ./laws/WireKeepsEveryArgument.bend as WireKeepsEveryArgument
import ./laws/WordCmpSelf.bend as WordCmpSelf
import ./laws/WordEq.bend as WordEq
