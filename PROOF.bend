# snap: the proofs. `bend PROOF.bend` is the check.
import Base
import ./LAWS.bend as Laws
import ./main.bend as Snap
import ./src/argv.bend as Argv
import ./src/answer.bend as Answer
import ./src/par.bend as Par
import ./src/file.bend as File
import ./check/LAWS.bend as Str
import ./check/PROOF.bend as StrProof

# a char of a status that holds no newline is not a newline
def not_nl(
  +ch: Char,
  +tail: String,
  h: {Str.clear(SCon{ch, tail}, '\n') == True{} : Bool}
) -> {Char.is_eq(ch, '\n') == False{} : Bool}:
  Str.not.true(Char.is_eq(ch, '\n'),
    Str.and.left(Bool.not(Char.is_eq(ch, '\n')), Str.clear(tail, '\n'), h))

# and the rest of the status holds none either
def clear_tail(
  +ch: Char,
  +tail: String,
  h: {Str.clear(SCon{ch, tail}, '\n') == True{} : Bool}
) -> {Str.clear(tail, '\n') == True{} : Bool}:
  Str.and.right(Bool.not(Char.is_eq(ch, '\n')), Str.clear(tail, '\n'), h)

# one char of the status, kept: it is no newline, so the reading goes on, and
# the rest of the status reads back by the induction hypothesis
def code_step(
  +ch: Char,
  +tail: String,
  +b: String,
  +h: {Str.clear(SCon{ch, tail}, '\n') == True{} : Bool},
  ih: {Str.clear(tail, '\n') == True{} : Bool} -> {Snap.code(tail ++ "\n" ++ b) == tail : String}
) -> {Snap.code(SCon{ch, tail} ++ "\n" ++ b) == SCon{ch, tail} : String}:
  Equal.trans(String,
    Answer.code.at(Char.is_eq(ch, '\n'), ch, _u => Snap.code(tail ++ "\n" ++ b)),
    Answer.code.at(False{}, ch, _u => Snap.code(tail ++ "\n" ++ b)),
    SCon{ch, tail},
    Equal.cong(Bool, String,
      nl => Answer.code.at(nl, ch, _u => Snap.code(tail ++ "\n" ++ b)),
      Char.is_eq(ch, '\n'), False{}, not_nl(ch, tail, h)),
    Equal.cong(String, String, x => SCon{ch, x},
      Snap.code(tail ++ "\n" ++ b), tail, ih(clear_tail(ch, tail, h))))

# by induction on the status: its chars are kept one by one, and the newline
# after it ends the reading
def Laws.code_reads_status(s, b, h):
  match s:
    case SNil{}:
      {==}
    case SCon{+ch, +tail}:
      code_step(ch, tail, b, h, hh => Laws.code_reads_status(tail, b, hh))

# one char of the status, skipped: it is no newline, so the body is still
# ahead, and the rest reads it back by the induction hypothesis
def text_step(
  +ch: Char,
  +tail: String,
  +b: String,
  +h: {Str.clear(SCon{ch, tail}, '\n') == True{} : Bool},
  ih: {Str.clear(tail, '\n') == True{} : Bool} -> {Snap.text(tail ++ "\n" ++ b) == b : String}
) -> {Snap.text(SCon{ch, tail} ++ "\n" ++ b) == b : String}:
  Equal.trans(String,
    Answer.text.at(Char.is_eq(ch, '\n'), tail ++ "\n" ++ b, _u => Snap.text(tail ++ "\n" ++ b)),
    Answer.text.at(False{}, tail ++ "\n" ++ b, _u => Snap.text(tail ++ "\n" ++ b)),
    b,
    Equal.cong(Bool, String,
      nl => Answer.text.at(nl, tail ++ "\n" ++ b, _u => Snap.text(tail ++ "\n" ++ b)),
      Char.is_eq(ch, '\n'), False{}, not_nl(ch, tail, h)),
    ih(clear_tail(ch, tail, h)))

# by induction on the status: its chars are skipped one by one, and the
# newline after it hands back the body as it stands
def Laws.text_reads_body(s, b, h):
  match s:
    case SNil{}:
      {==}
    case SCon{+ch, +tail}:
      text_step(ch, tail, b, h, hh => Laws.text_reads_body(tail, b, hh))

def Laws.ok_reads_zero(s, b, h):
  Equal.cong(String, Bool, x => String.eq(x, "0"),
    Snap.code(s ++ "\n" ++ b), s, Laws.code_reads_status(s, b, h))

# `free_of` is `clear`: the same walk, by induction on the string
def free_of_is_clear(
  text: String,
  +sep: Char
) -> {Argv.free_of(text, sep) == Str.clear(text, sep) : Bool}:
  match text:
    case SNil{}:
      {==}
    case SCon{+ch, +tail}:
      Equal.cong(Bool, Bool, r => Bool.and(Bool.not(Char.is_eq(ch, sep)), r),
        Argv.free_of(tail, sep), Str.clear(tail, sep), free_of_is_clear(tail, sep))

# and `free_of.all` is `clear.all`, piece by piece
def free_of_all_is_clear_all(
  ps: List<&2, String>,
  +sep: Char
) -> {Argv.free_of.all(ps, sep) == Str.clear.all(ps, sep) : Bool}:
  match ps:
    case []:
      {==}
    case +pc <> +pt:
      Equal.trans(Bool,
        Bool.and(Argv.free_of(pc, sep), Argv.free_of.all(pt, sep)),
        Bool.and(Str.clear(pc, sep), Argv.free_of.all(pt, sep)),
        Bool.and(Str.clear(pc, sep), Str.clear.all(pt, sep)),
        Equal.cong(Bool, Bool, x => Bool.and(x, Argv.free_of.all(pt, sep)),
          Argv.free_of(pc, sep), Str.clear(pc, sep), free_of_is_clear(pc, sep)),
        Equal.cong(Bool, Bool, y => Bool.and(Str.clear(pc, sep), y),
          Argv.free_of.all(pt, sep), Str.clear.all(pt, sep),
          free_of_all_is_clear_all(pt, sep)))

# anything and false is false
def and_false(a: Bool) -> {Bool.and(a, False{}) == False{} : Bool}:
  match a:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.wire_round_trip(argv, h):
  match argv:
    case []:
      Empty.absurd({Laws.wire.split(Argv.wire([])) == [] : List<&2, String>}, StrProof.bit.clash(h))
    case +prog <> +args:
      Str.split_join(prog, args, '\0',
        Equal.trans(Bool,
          Str.clear.all(prog <> args, '\0'),
          Argv.free_of.all(prog <> args, '\0'),
          True{},
          Equal.sym(Bool, Argv.free_of.all(prog <> args, '\0'),
            Str.clear.all(prog <> args, '\0'),
            free_of_all_is_clear_all(prog <> args, '\0')),
          Str.and.right(Bool.not(String.is_empty(prog)),
            Argv.free_of.all(prog <> args, '\0'), h)))

def Laws.refuses_empty(argv, h):
  match argv:
    case []:
      {==}
    case +prog <> +args:
      Empty.absurd({Argv.run.plan(prog <> args) == Argv.Refused{} : Argv.Step},
        StrProof.bit.clash(h))

def Laws.refuses_no_program(_args):
  {==}

# an argv whose pieces are not all NUL-free is not accepted
def accepts_false(
  +prog: String,
  +args: List<&2, String>,
  h: {Argv.free_of.all(prog <> args, '\0') == False{} : Bool}
) -> {Argv.run.plan(prog <> args) == Argv.Refused{} : Argv.Step}:
  Equal.cong(Bool, Argv.Step, ok => Argv.run.plan.of(ok, prog <> args),
    Argv.accepts(prog <> args), False{},
    Equal.trans(Bool,
      Bool.and(Bool.not(String.is_empty(prog)), Argv.free_of.all(prog <> args, '\0')),
      Bool.and(Bool.not(String.is_empty(prog)), False{}),
      False{},
      Equal.cong(Bool, Bool, y => Bool.and(Bool.not(String.is_empty(prog)), y),
        Argv.free_of.all(prog <> args, '\0'), False{}, h),
      and_false(Bool.not(String.is_empty(prog)))))

# a list with a piece holding NUL somewhere is not all NUL-free, by induction
# on the pieces before it
def nul_somewhere(
  +pre: List<&2, String>,
  +x: String,
  +post: List<&2, String>,
  h: {Argv.free_of(x, '\0') == False{} : Bool}
) -> {Argv.free_of.all(List.append(&2, String, pre, x <> post), '\0') == False{} : Bool}:
  match pre:
    case []:
      Equal.cong(Bool, Bool, v => Bool.and(v, Argv.free_of.all(post, '\0')),
        Argv.free_of(x, '\0'), False{}, h)
    case +pc <> +pt:
      Equal.trans(Bool,
        Bool.and(Argv.free_of(pc, '\0'),
          Argv.free_of.all(List.append(&2, String, pt, x <> post), '\0')),
        Bool.and(Argv.free_of(pc, '\0'), False{}),
        False{},
        Equal.cong(Bool, Bool, y => Bool.and(Argv.free_of(pc, '\0'), y),
          Argv.free_of.all(List.append(&2, String, pt, x <> post), '\0'), False{},
          nul_somewhere(pt, x, post, h)),
        and_false(Argv.free_of(pc, '\0')))

# the argv as a program and its arguments, which is the shape `accepts` reads
def refuses_nul.at(
  +pre: List<&2, String>,
  +x: String,
  +post: List<&2, String>,
  +h: {Argv.free_of(x, '\0') == False{} : Bool}
) -> {Argv.run.plan(List.append(&2, String, pre, x <> post)) == Argv.Refused{} : Argv.Step}:
  match pre:
    case []:
      accepts_false(x, post, nul_somewhere([], x, post, h))
    case +pc <> +pt:
      accepts_false(pc, List.append(&2, String, pt, x <> post),
        nul_somewhere(pc <> pt, x, post, h))

def Laws.refuses_nul(pre, x, post, h):
  refuses_nul.at(pre, x, post,
    Equal.trans(Bool, Argv.free_of(x, '\0'), Str.clear(x, '\0'), False{},
      free_of_is_clear(x, '\0'), h))

def Laws.runs_accepted(prog, args, hp, ha):
  Equal.cong(Bool, Argv.Step, ok => Argv.run.plan.of(ok, prog <> args),
    Argv.accepts(prog <> args), True{},
    Equal.trans(Bool,
      Bool.and(Bool.not(String.is_empty(prog)), Argv.free_of.all(prog <> args, '\0')),
      Argv.free_of.all(prog <> args, '\0'),
      True{},
      Equal.cong(Bool, Bool, v => Bool.and(Bool.not(v), Argv.free_of.all(prog <> args, '\0')),
        String.is_empty(prog), False{}, hp),
      Equal.trans(Bool,
        Argv.free_of.all(prog <> args, '\0'),
        Str.clear.all(prog <> args, '\0'),
        True{},
        free_of_all_is_clear_all(prog <> args, '\0'),
        ha)))

def Laws.refused_run_calls_nothing(eff, argv, h):
  Equal.cong(Argv.Step, IO(String), st => Argv.run.with(eff, st),
    Argv.run.plan(argv), Argv.Refused{}, h)

def Laws.refused_start_calls_nothing(eff, argv, h):
  Equal.cong(Argv.Step, IO(String), st => Argv.start.with(eff, st),
    Argv.run.plan(argv), Argv.Refused{}, h)

# two true bits and together to true
def and.both(
  a: Bool,
  b: Bool,
  ea: {a == True{} : Bool},
  eb: {b == True{} : Bool}
) -> {Bool.and(a, b) == True{} : Bool}:
  Equal.trans(Bool, Bool.and(a, b), Bool.and(True{}, b), True{},
    Equal.cong(Bool, Bool, v => Bool.and(v, b), a, True{}, ea), eb)

# two lists clear of a char, one after the other, are clear of it
def all_append(
  xs: List<&2, String>,
  +ys: List<&2, String>,
  +sep: Char,
  +ex: {Str.clear.all(xs, sep) == True{} : Bool},
  ey: {Str.clear.all(ys, sep) == True{} : Bool}
) -> {Str.clear.all(List.append(&2, String, xs, ys), sep) == True{} : Bool}:
  match xs:
    case []:
      ey
    case +xh <> +xt:
      and.both(Str.clear(xh, sep), Str.clear.all(List.append(&2, String, xt, ys), sep),
        Str.and.left(Str.clear(xh, sep), Str.clear.all(xt, sep), ex),
        all_append(xt, ys, sep, Str.and.right(Str.clear(xh, sep), Str.clear.all(xt, sep), ex), ey))

# a job's fields are clear of NUL when its arguments are: a mark is no NUL,
# and the field that ends it is empty
def job_fields_clear(
  argv: List<&2, String>,
  +ha: {Str.clear.all(argv, '\0') == True{} : Bool}
) -> {Str.clear.all(Par.job.fields(argv), '\0') == True{} : Bool}:
  match argv:
    case []:
      {==}
    case +arg <> +rest:
      and.both(Str.clear(arg, '\0'), Str.clear.all(Par.job.fields(rest), '\0'),
        Str.and.left(Str.clear(arg, '\0'), Str.clear.all(rest, '\0'), ha),
        job_fields_clear(rest, Str.and.right(Str.clear(arg, '\0'), Str.clear.all(rest, '\0'), ha)))

# an accepted argv is clear of NUL
def accepted_clear(
  argv: List<&2, String>,
  h: {Argv.accepts(argv) == True{} : Bool}
) -> {Str.clear.all(argv, '\0') == True{} : Bool}:
  match argv:
    case []:
      Empty.absurd({Str.clear.all([], '\0') == True{} : Bool}, StrProof.bit.clash(h))
    case +prog <> +args:
      Equal.trans(Bool,
        Str.clear.all(prog <> args, '\0'),
        Argv.free_of.all(prog <> args, '\0'),
        True{},
        Equal.sym(Bool, Argv.free_of.all(prog <> args, '\0'),
          Str.clear.all(prog <> args, '\0'),
          free_of_all_is_clear_all(prog <> args, '\0')),
        Str.and.right(Bool.not(String.is_empty(prog)),
          Argv.free_of.all(prog <> args, '\0'), h))

# the job `par` sends, whichever way `accepts` went, has fields clear of NUL
def sent_clear.at(
  ok: Bool,
  +job: List<&2, String>,
  e: {Argv.accepts(job) == ok : Bool}
) -> {Str.clear.all(Par.job.fields(Par.par.job.of(ok, job)), '\0') == True{} : Bool}:
  match ok:
    case True{}:
      job_fields_clear(job, accepted_clear(job, e))
    case False{}:
      {==}

# every job's fields are clear of NUL
def fields_clear(
  js: List<&2, List<&2, String>>
) -> {Str.clear.all(Par.par.fields(js), '\0') == True{} : Bool}:
  match js:
    case []:
      {==}
    case +job <> +rest:
      all_append(Par.job.fields(Par.par.job(job)), Par.par.fields(rest), '\0',
        sent_clear.at(Argv.accepts(job), job, {==}), fields_clear(rest))

# a job's fields, read before the rest, are that job in front of the rest's
def jobs_of_job(
  argv: List<&2, String>,
  +rest: List<&2, String>
) -> {Laws.jobs.of(List.append(&2, String, Par.job.fields(argv), rest)) == argv <> Laws.jobs.of(rest)
  : List<&2, List<&2, String>>}:
  match argv:
    case []:
      {==}
    case +arg <> +more:
      Equal.cong(List<&2, List<&2, String>>, List<&2, List<&2, String>>,
        gs => Laws.jobs.push(arg, gs),
        Laws.jobs.of(List.append(&2, String, Par.job.fields(more), rest)),
        more <> Laws.jobs.of(rest),
        jobs_of_job(more, rest))

# and every job's fields read back as the jobs sent, in order
def jobs_of_fields(
  js: List<&2, List<&2, String>>
) -> {Laws.jobs.of(Par.par.fields(js)) == Laws.jobs.sent(js) : List<&2, List<&2, String>>}:
  match js:
    case []:
      {==}
    case +job <> +rest:
      Equal.trans(List<&2, List<&2, String>>,
        Laws.jobs.of(List.append(&2, String, Par.job.fields(Par.par.job(job)), Par.par.fields(rest))),
        Par.par.job(job) <> Laws.jobs.of(Par.par.fields(rest)),
        Par.par.job(job) <> Laws.jobs.sent(rest),
        jobs_of_job(Par.par.job(job), Par.par.fields(rest)),
        Equal.cong(List<&2, List<&2, String>>, List<&2, List<&2, String>>,
          gs => Par.par.job(job) <> gs,
          Laws.jobs.of(Par.par.fields(rest)), Laws.jobs.sent(rest), jobs_of_fields(rest)))

# the header's four fields taken, and the rest dropped, whatever the rest is
def header_cut(
  +width: String,
  +gb: String,
  +at: String,
  +by: String,
  fields: List<&2, String>
) -> {Laws.Split{width <> gb <> at <> by <> List.take(&2, String, fields, 0n),
    Laws.jobs.of(List.drop(&2, String, fields, 0n))}
  == Laws.Split{[width, gb, at, by], Laws.jobs.of(fields)} : Laws.Split}:
  match fields:
    case []:
      {==}
    case field <> rest:
      {==}

def Laws.par_plan_round_trip(js, width, gb, at, by, h):
  Equal.trans(Laws.Split,
    Laws.plan.split(Par.par.plan(js, width, gb, at, by)),
    Laws.Split{[width, gb, at, by], Laws.jobs.of(Par.par.fields(js))},
    Laws.Split{[width, gb, at, by], Laws.jobs.sent(js)},
    Equal.trans(Laws.Split,
      Laws.plan.split(Par.par.plan(js, width, gb, at, by)),
      Laws.Split{width <> gb <> at <> by <> List.take(&2, String, Par.par.fields(js), 0n),
        Laws.jobs.of(List.drop(&2, String, Par.par.fields(js), 0n))},
      Laws.Split{[width, gb, at, by], Laws.jobs.of(Par.par.fields(js))},
      Equal.cong(List<&2, String>, Laws.Split,
        fs => Laws.Split{List.take(&2, String, fs, 4n), Laws.jobs.of(List.drop(&2, String, fs, 4n))},
        Laws.wire.split(Par.par.plan(js, width, gb, at, by)),
        width <> gb <> at <> by <> Par.par.fields(js),
        Str.split_join(width, gb <> at <> by <> Par.par.fields(js), '\0',
          all_append([width, gb, at, by], Par.par.fields(js), '\0', h, fields_clear(js)))),
      header_cut(width, gb, at, by, Par.par.fields(js))),
    Equal.cong(List<&2, List<&2, String>>, Laws.Split, x => Laws.Split{[width, gb, at, by], x},
      Laws.jobs.of(Par.par.fields(js)), Laws.jobs.sent(js), jobs_of_fields(js)))

# the induction hypothesis for the statuses: the rest's answers read back
# the rest's statuses, whatever bodies they are paired with
def ih.codes(ct: List<&2, String>, bs: List<&2, Maybe<&2, String>>) -> Type:
  {Str.clear.all(ct, '\n') == True{} : Bool} -> {Laws.codes(Par.par.answers(ct, bs)) == ct : List<&2, String>}

# and for the bodies: the rest's answers read back the bodies they are owed
def ih.texts(ct: List<&2, String>, bs: List<&2, Maybe<&2, String>>) -> Type:
  {Str.clear.all(ct, '\n') == True{} : Bool} ->
    {Laws.texts(Par.par.answers(ct, bs)) == Laws.bodies.owed(ct, bs) : List<&2, String>}

# one answer's status, read back, then the rest's
def answers_codes.at(
  +code: String,
  +ct: List<&2, String>,
  bodies: List<&2, Maybe<&2, String>>,
  +h: {Str.clear.all(code <> ct, '\n') == True{} : Bool},
  ih: @bs: List<&2, Maybe<&2, String>> -> ih.codes(ct, bs)
) -> {Laws.codes(Par.par.answers(code <> ct, bodies)) == code <> ct : List<&2, String>}:
  match bodies:
    case []:
      Equal.trans(List<&2, String>,
        Snap.code(Par.par.of(code, None{})) <> Laws.codes(Par.par.answers(ct, [])),
        code <> Laws.codes(Par.par.answers(ct, [])),
        code <> ct,
        Equal.cong(String, List<&2, String>, x => x <> Laws.codes(Par.par.answers(ct, [])),
          Snap.code(Par.par.of(code, None{})), code,
          Laws.code_reads_status(code, "", Str.and.left(Str.clear(code, '\n'), Str.clear.all(ct, '\n'), h))),
        Equal.cong(List<&2, String>, List<&2, String>, y => code <> y,
          Laws.codes(Par.par.answers(ct, [])), ct,
          ih([], Str.and.right(Str.clear(code, '\n'), Str.clear.all(ct, '\n'), h))))
    case +body <> +bt:
      Equal.trans(List<&2, String>,
        Snap.code(Par.par.of(code, body)) <> Laws.codes(Par.par.answers(ct, bt)),
        code <> Laws.codes(Par.par.answers(ct, bt)),
        code <> ct,
        Equal.cong(String, List<&2, String>, x => x <> Laws.codes(Par.par.answers(ct, bt)),
          Snap.code(Par.par.of(code, body)), code,
          Laws.code_reads_status(code, File.file.text_of(body),
            Str.and.left(Str.clear(code, '\n'), Str.clear.all(ct, '\n'), h))),
        Equal.cong(List<&2, String>, List<&2, String>, y => code <> y,
          Laws.codes(Par.par.answers(ct, bt)), ct,
          ih(bt, Str.and.right(Str.clear(code, '\n'), Str.clear.all(ct, '\n'), h))))

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
  +h: {Str.clear.all(code <> ct, '\n') == True{} : Bool},
  ih: @bs: List<&2, Maybe<&2, String>> -> ih.texts(ct, bs)
) -> {Laws.texts(Par.par.answers(code <> ct, bodies)) == Laws.bodies.owed(code <> ct, bodies) : List<&2, String>}:
  match bodies:
    case []:
      Equal.trans(List<&2, String>,
        Snap.text(Par.par.of(code, None{})) <> Laws.texts(Par.par.answers(ct, [])),
        "" <> Laws.texts(Par.par.answers(ct, [])),
        "" <> Laws.bodies.owed(ct, []),
        Equal.cong(String, List<&2, String>, x => x <> Laws.texts(Par.par.answers(ct, [])),
          Snap.text(Par.par.of(code, None{})), "",
          Laws.text_reads_body(code, "", Str.and.left(Str.clear(code, '\n'), Str.clear.all(ct, '\n'), h))),
        Equal.cong(List<&2, String>, List<&2, String>, y => "" <> y,
          Laws.texts(Par.par.answers(ct, [])), Laws.bodies.owed(ct, []),
          ih([], Str.and.right(Str.clear(code, '\n'), Str.clear.all(ct, '\n'), h))))
    case +body <> +bt:
      Equal.trans(List<&2, String>,
        Snap.text(Par.par.of(code, body)) <> Laws.texts(Par.par.answers(ct, bt)),
        File.file.text_of(body) <> Laws.texts(Par.par.answers(ct, bt)),
        File.file.text_of(body) <> Laws.bodies.owed(ct, bt),
        Equal.cong(String, List<&2, String>, x => x <> Laws.texts(Par.par.answers(ct, bt)),
          Snap.text(Par.par.of(code, body)), File.file.text_of(body),
          Laws.text_reads_body(code, File.file.text_of(body),
            Str.and.left(Str.clear(code, '\n'), Str.clear.all(ct, '\n'), h))),
        Equal.cong(List<&2, String>, List<&2, String>, y => File.file.text_of(body) <> y,
          Laws.texts(Par.par.answers(ct, bt)), Laws.bodies.owed(ct, bt),
          ih(bt, Str.and.right(Str.clear(code, '\n'), Str.clear.all(ct, '\n'), h))))

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
          Str.not.true(String.is_empty(str),
            Str.and.left(Bool.not(String.is_empty(str)), Laws.filled.all(rest), hf))),
        Equal.cong(List<&2, String>, List<&2, String>, y => str <> y,
          Par.par.nonblank(rest), rest,
          nonblank_filled(rest, Str.and.right(Bool.not(String.is_empty(str)), Laws.filled.all(rest), hf))))

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
          Str.split_join(code, ct, '\n', h)),
        nonblank_filled(code <> ct, hf))

def Laws.cmd_round_trip(prog, args, h):
  Str.split_join(prog, args, '\n', h)

def Laws.line_round_trip(prog, args, h):
  Str.split_join(prog, args, '\n', h)
