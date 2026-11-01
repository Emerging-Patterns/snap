# proofs of laws/ParWireKeepsEveryJob.bend
import Base
import ../src/argv.bend as Argv
import ../src/par.bend as Par
import ../laws/AndLeft.bend as L1
import ../laws/AndRight.bend as L2
import ../laws/ParWireKeepsEveryJob.bend as Laws
import ../laws/SplitJoin.bend as L3
import ../laws/defs/HoldsNoChar.bend as D1
import ../laws/defs/WireSplit.bend as D2
import ./lemmas/SplitRejoins.bend as M1
import ./lemmas/StatusReading.bend as M2

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
  +ex: {D1.clear.all(xs, sep) == True{} : Bool},
  ey: {D1.clear.all(ys, sep) == True{} : Bool}
) -> {D1.clear.all(List.append(&2, String, xs, ys), sep) == True{} : Bool}:
  match xs:
    case []:
      ey
    case +xh <> +xt:
      and.both(D1.clear(xh, sep), D1.clear.all(List.append(&2, String, xt, ys), sep),
        L1.and.left(D1.clear(xh, sep), D1.clear.all(xt, sep), ex),
        all_append(xt, ys, sep, L2.and.right(D1.clear(xh, sep), D1.clear.all(xt, sep), ex), ey))

# a job's fields are clear of NUL when its arguments are: a mark is no NUL,
# and the field that ends it is empty
def job_fields_clear(
  argv: List<&2, String>,
  +ha: {D1.clear.all(argv, '\0') == True{} : Bool}
) -> {D1.clear.all(Par.job.fields(argv), '\0') == True{} : Bool}:
  match argv:
    case []:
      {==}
    case +arg <> +rest:
      and.both(D1.clear(arg, '\0'), D1.clear.all(Par.job.fields(rest), '\0'),
        L1.and.left(D1.clear(arg, '\0'), D1.clear.all(rest, '\0'), ha),
        job_fields_clear(rest, L2.and.right(D1.clear(arg, '\0'), D1.clear.all(rest, '\0'), ha)))

# an accepted argv is clear of NUL
def accepted_clear(
  argv: List<&2, String>,
  h: {Argv.accepts(argv) == True{} : Bool}
) -> {D1.clear.all(argv, '\0') == True{} : Bool}:
  match argv:
    case []:
      Empty.absurd({D1.clear.all([], '\0') == True{} : Bool}, M2.bit.clash(h))
    case +prog <> +args:
      Equal.trans(Bool,
        D1.clear.all(prog <> args, '\0'),
        Argv.free_of.all(prog <> args, '\0'),
        True{},
        Equal.sym(Bool, Argv.free_of.all(prog <> args, '\0'),
          D1.clear.all(prog <> args, '\0'),
          M2.free_of_all_is_clear_all(prog <> args, '\0')),
        L2.and.right(Bool.not(String.is_empty(prog)),
          Argv.free_of.all(prog <> args, '\0'), h))

# the job `par` sends, whichever way `accepts` went, has fields clear of NUL
def sent_clear.at(
  ok: Bool,
  +job: List<&2, String>,
  e: {Argv.accepts(job) == ok : Bool}
) -> {D1.clear.all(Par.job.fields(Par.par.job.of(ok, job)), '\0') == True{} : Bool}:
  match ok:
    case True{}:
      job_fields_clear(job, accepted_clear(job, e))
    case False{}:
      {==}

# every job's fields are clear of NUL
def fields_clear(
  js: List<&2, List<&2, String>>
) -> {D1.clear.all(Par.par.fields(js), '\0') == True{} : Bool}:
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
        D2.wire.split(Par.par.plan(js, width, gb, at, by)),
        width <> gb <> at <> by <> Par.par.fields(js),
        L3.split_join(width, gb <> at <> by <> Par.par.fields(js), '\0',
          all_append([width, gb, at, by], Par.par.fields(js), '\0', h, fields_clear(js)))),
      header_cut(width, gb, at, by, Par.par.fields(js))),
    Equal.cong(List<&2, List<&2, String>>, Laws.Split, x => Laws.Split{[width, gb, at, by], x},
      Laws.jobs.of(Par.par.fields(js)), Laws.jobs.sent(js), jobs_of_fields(js)))
