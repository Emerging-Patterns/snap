# For every job list and every header whose fields hold no NUL,
# `plan.split(par.plan(js, width, gb, at, by))` is exactly the header and one
# job per job of `js`, in order, each the job's argv when it `accepts` and the
# empty job otherwise.
import Base
import ../src/par.bend as Par
import ./defs/HoldsNoChar.bend as D1
import ./defs/WireSplit.bend as D2

# Running several at once. `par` decides in `par.plan` which jobs it sends
# and how they are framed, and in `par.answers` how each status is paired
# with the body its job wrote.

# the header and the jobs a `par` wire holds, as the effects read it
type Split is Data:
  Split{header: List<&2, String>, jobs: List<&2, List<&2, String>>}

# one field onto the jobs read so far, read from the end: an empty field
# starts a job, and a marked one is an argument of the job it sits in, its
# mark stepped over
def jobs.push(arg: String, jobs: List<&2, List<&2, String>>) -> List<&2, List<&2, String>>:
  match jobs:
    case []:
      [[arg]]
    case job <> rest:
      (arg <> job) <> rest

# a field read onto the jobs after it
def jobs.step(field: String, jobs: List<&2, List<&2, String>>) -> List<&2, List<&2, String>>:
  match field:
    case SNil{}:
      [] <> jobs
    case SCon{_mark, arg}:
      jobs.push(arg, jobs)

# the jobs a run of fields holds
def jobs.of(fields: List<&2, String>) -> List<&2, List<&2, String>>:
  match fields:
    case []:
      []
    case field <> rest:
      jobs.step(field, jobs.of(rest))

# how every `par` effect reads its wire: cut at each NUL, the first four
# fields the header, and the jobs after them. Law vocabulary: the effects do
# this in C and JS, and that they read it exactly so is trusted (trusted in
# src/effect.bend).
def plan.split(wr: String) -> Split:
  +fields = D2.wire.split(wr)
  Split{List.take(&2, String, fields, 4n), jobs.of(List.drop(&2, String, fields, 4n))}

# the job `par` sends for each job it was given, in order
def jobs.sent(js: List<&2, List<&2, String>>) -> List<&2, List<&2, String>>:
  match js:
    case []:
      []
    case job <> rest:
      Par.par.job(job) <> jobs.sent(rest)

# LAW: the effect reads back exactly the header and one job per job given, in
# order: each job as it was when `run` would accept it, and the empty job,
# which it answers 127, when not
law par_plan_round_trip:
  for +js: List<&2, List<&2, String>>
  for +width: String
  for +gb: String
  for +at: String
  for +by: String
  for h: {D1.clear.all([width, gb, at, by], '\0') == True{} : Bool}
  {plan.split(Par.par.plan(js, width, gb, at, by))
    == Split{[width, gb, at, by], jobs.sent(js)} : Split}
