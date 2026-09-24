// snaprun.par: the JS lane's twin of par.c. The fields arrive the way par.c
// takes them, NUL separated, each job's arguments marked with a `+` and ended
// by an empty field, and go straight to spawnSync, so no shell parses them.
//
// This one runs the jobs in turn rather than at once. Bend's JS effects answer
// synchronously, and node has no way to wait on several spawned children from
// inside a synchronous call. The answer is every status, in the order the
// jobs were given.
function snaprun_par(cmd) {
  const cp = require("child_process");
  const fs = require("fs");
  const line = cmd.split("\0");
  const dir = line.length > 2 ? line[2] : ".";
  const by = line.length > 3 ? parseInt(line[3], 10) : 0;
  // the jobs: the marked fields up to each empty one, marks stepped over
  const jobs = [];
  let args = [];
  for (let i = 4; i < line.length; i++) {
    if (line[i] === "") {
      jobs.push(args);
      args = [];
    } else {
      args.push(line[i].slice(1));
    }
  }
  // a job that is not run still has its file emptied, so nothing an earlier
  // run left there is read back as its output
  const empty = (path) => {
    try {
      fs.writeFileSync(path, "");
    } catch (e) {
      // no file to empty is no file to read back
    }
  };
  const codes = [];
  for (let n = 0; n < jobs.length; n++) {
    const args = jobs[n];
    const spare = by > 0 ? by - Math.floor(Date.now() / 1000) : 0;
    if (args.length === 0 || (by > 0 && spare <= 0)) {
      empty(dir + "/" + n);
      codes.push(args.length === 0 ? 127 : 124);
      continue;
    }
    const out = fs.openSync(dir + "/" + n, "w");
    try {
      const r = cp.spawnSync(args[0], args.slice(1),
        { stdio: ["ignore", out, out], timeout: by > 0 ? spare * 1000 : undefined });
      codes.push(r.error !== undefined && r.error !== null ? 127 : r.status === null ? 124 : r.status);
    } catch (e) {
      codes.push(127);
    }
    fs.closeSync(out);
  }
  return codes.join("\n");
}
