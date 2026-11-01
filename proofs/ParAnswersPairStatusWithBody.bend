# proofs of laws/ParAnswersPairStatusWithBody.bend
import Base
import ../src/answer.bend as Answer
import ../src/par.bend as Par
import ../src/file.bend as File
import ../laws/AndLeft.bend as L1
import ../laws/AndRight.bend as L2
import ../laws/CodeReadsStatus.bend as L3
import ../laws/NotTrue.bend as L4
import ../laws/ParAnswersPairStatusWithBody.bend as Laws
import ../laws/SplitJoin.bend as L5
import ../laws/TextReadsBody.bend as L6
import ../laws/defs/HoldsNoChar.bend as D1
import ./lemmas/SplitRejoins.bend as M1
import ./lemmas/StatusReading.bend as M2

# the induction hypothesis for the statuses: the rest's answers read back
# the rest's statuses, whatever bodies they are paired with
def ih.codes(ct: List<&2, String>, bs: List<&2, Maybe<&2, String>>) -> Type:
  {D1.clear.all(ct, '\n') == True{} : Bool} -> {Laws.codes(Par.par.answers(ct, bs)) == ct : List<&2, String>}

# and for the bodies: the rest's answers read back the bodies they are owed
def ih.texts(ct: List<&2, String>, bs: List<&2, Maybe<&2, String>>) -> Type:
  {D1.clear.all(ct, '\n') == True{} : Bool} ->
    {Laws.texts(Par.par.answers(ct, bs)) == Laws.bodies.owed(ct, bs) : List<&2, String>}

# one answer's status, read back, then the rest's
def answers_codes.at(
  +code: String,
  +ct: List<&2, String>,
  bodies: List<&2, Maybe<&2, String>>,
  +h: {D1.clear.all(code <> ct, '\n') == True{} : Bool},
  ih: @bs: List<&2, Maybe<&2, String>> -> ih.codes(ct, bs)
) -> {Laws.codes(Par.par.answers(code <> ct, bodies)) == code <> ct : List<&2, String>}:
  match bodies:
    case []:
      Equal.trans(List<&2, String>,
        Answer.code(Par.par.of(code, None{})) <> Laws.codes(Par.par.answers(ct, [])),
        code <> Laws.codes(Par.par.answers(ct, [])),
        code <> ct,
        Equal.cong(String, List<&2, String>, x => x <> Laws.codes(Par.par.answers(ct, [])),
          Answer.code(Par.par.of(code, None{})), code,
          L3.code_reads_status(code, "", L1.and.left(D1.clear(code, '\n'), D1.clear.all(ct, '\n'), h))),
        Equal.cong(List<&2, String>, List<&2, String>, y => code <> y,
          Laws.codes(Par.par.answers(ct, [])), ct,
          ih([], L2.and.right(D1.clear(code, '\n'), D1.clear.all(ct, '\n'), h))))
    case +body <> +bt:
      Equal.trans(List<&2, String>,
        Answer.code(Par.par.of(code, body)) <> Laws.codes(Par.par.answers(ct, bt)),
        code <> Laws.codes(Par.par.answers(ct, bt)),
        code <> ct,
        Equal.cong(String, List<&2, String>, x => x <> Laws.codes(Par.par.answers(ct, bt)),
          Answer.code(Par.par.of(code, body)), code,
          L3.code_reads_status(code, File.file.text_of(body),
            L1.and.left(D1.clear(code, '\n'), D1.clear.all(ct, '\n'), h))),
        Equal.cong(List<&2, String>, List<&2, String>, y => code <> y,
          Laws.codes(Par.par.answers(ct, bt)), ct,
          ih(bt, L2.and.right(D1.clear(code, '\n'), D1.clear.all(ct, '\n'), h))))

def Laws.par_answers_codes(cs, bodies, h):
  match cs:
    case []:
      {==}
    case +code <> +ct:
      answers_codes.at(code, ct, bodies, h, bs => hh => Laws.par_answers_codes(ct, bs, hh))

# one answer's body, read back, then the rest's
def answers_texts.at(
  +code: String,
  +ct: List<&2, String>,
  bodies: List<&2, Maybe<&2, String>>,
  +h: {D1.clear.all(code <> ct, '\n') == True{} : Bool},
  ih: @bs: List<&2, Maybe<&2, String>> -> ih.texts(ct, bs)
) -> {Laws.texts(Par.par.answers(code <> ct, bodies)) == Laws.bodies.owed(code <> ct, bodies) : List<&2, String>}:
  match bodies:
    case []:
      Equal.trans(List<&2, String>,
        Answer.text(Par.par.of(code, None{})) <> Laws.texts(Par.par.answers(ct, [])),
        "" <> Laws.texts(Par.par.answers(ct, [])),
        "" <> Laws.bodies.owed(ct, []),
        Equal.cong(String, List<&2, String>, x => x <> Laws.texts(Par.par.answers(ct, [])),
          Answer.text(Par.par.of(code, None{})), "",
          L6.text_reads_body(code, "", L1.and.left(D1.clear(code, '\n'), D1.clear.all(ct, '\n'), h))),
        Equal.cong(List<&2, String>, List<&2, String>, y => "" <> y,
          Laws.texts(Par.par.answers(ct, [])), Laws.bodies.owed(ct, []),
          ih([], L2.and.right(D1.clear(code, '\n'), D1.clear.all(ct, '\n'), h))))
    case +body <> +bt:
      Equal.trans(List<&2, String>,
        Answer.text(Par.par.of(code, body)) <> Laws.texts(Par.par.answers(ct, bt)),
        File.file.text_of(body) <> Laws.texts(Par.par.answers(ct, bt)),
        File.file.text_of(body) <> Laws.bodies.owed(ct, bt),
        Equal.cong(String, List<&2, String>, x => x <> Laws.texts(Par.par.answers(ct, bt)),
          Answer.text(Par.par.of(code, body)), File.file.text_of(body),
          L6.text_reads_body(code, File.file.text_of(body),
            L1.and.left(D1.clear(code, '\n'), D1.clear.all(ct, '\n'), h))),
        Equal.cong(List<&2, String>, List<&2, String>, y => File.file.text_of(body) <> y,
          Laws.texts(Par.par.answers(ct, bt)), Laws.bodies.owed(ct, bt),
          ih(bt, L2.and.right(D1.clear(code, '\n'), D1.clear.all(ct, '\n'), h))))

def Laws.par_answers_texts(cs, bodies, h):
  match cs:
    case []:
      {==}
    case +code <> +ct:
      answers_texts.at(code, ct, bodies, h, bs => hh => Laws.par_answers_texts(ct, bs, hh))

# statuses that each have a char are kept, every one
def nonblank_filled(
  ss: List<&2, String>,
  +hf: {Laws.filled.all(ss) == True{} : Bool}
) -> {Par.par.nonblank(ss) == ss : List<&2, String>}:
  match ss:
    case []:
      {==}
    case +str <> +rest:
      Equal.trans(List<&2, String>,
        Bool.pick(List<&2, String>, String.is_empty(str), Par.par.nonblank(rest), str <> Par.par.nonblank(rest)),
        str <> Par.par.nonblank(rest),
        str <> rest,
        Equal.cong(Bool, List<&2, String>,
          b => Bool.pick(List<&2, String>, b, Par.par.nonblank(rest), str <> Par.par.nonblank(rest)),
          String.is_empty(str), False{},
          L4.not.true(String.is_empty(str),
            L1.and.left(Bool.not(String.is_empty(str)), Laws.filled.all(rest), hf))),
        Equal.cong(List<&2, String>, List<&2, String>, y => str <> y,
          Par.par.nonblank(rest), rest,
          nonblank_filled(rest, L2.and.right(Bool.not(String.is_empty(str)), Laws.filled.all(rest), hf))))

def Laws.par_statuses_read_back(cs, h, hf):
  match cs:
    case []:
      {==}
    case +code <> +ct:
      Equal.trans(List<&2, String>,
        Par.par.nonblank(String.lines(String.join(code <> ct, "\n"))),
        Par.par.nonblank(code <> ct),
        code <> ct,
        Equal.cong(List<&2, String>, List<&2, String>, ls => Par.par.nonblank(ls),
          String.lines(String.join(code <> ct, "\n")), code <> ct,
          L5.split_join(code, ct, '\n', h)),
        nonblank_filled(code <> ct, hf))
