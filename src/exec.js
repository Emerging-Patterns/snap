// snaprun.exec: the JS lane's twin of exec.c. The arguments arrive NUL
// separated and go straight to spawnSync, so no shell parses them.
//
// The answer is exec.c's, byte for byte in shape: the exit status on its own
// first line, 128 plus the signal for a program a signal ended, 127 for one
// that could not be started, then everything it printed. stdout and stderr
// both go to one temporary file, as exec.c points both at one pipe, so what
// the program wrote arrives in the order it wrote it, and with no cap on its
// size (spawnSync's own pipes stop at maxBuffer).
function snaprun_exec(cmd) {
  const cp = require("child_process");
  const fs = require("fs");
  const os = require("os");
  const path = require("path");
  const args = cmd.split("\0");
  let dir = null;
  try {
    dir = fs.mkdtempSync(path.join(os.tmpdir(), "snaprun-"));
    const file = path.join(dir, "out");
    const out = fs.openSync(file, "w");
    let r;
    try {
      r = cp.spawnSync(args[0], args.slice(1), { stdio: ["ignore", out, out] });
    } finally {
      fs.closeSync(out);
    }
    const code = r.error !== undefined && r.error !== null ? 127
      : r.status !== null ? r.status
      : 128 + (os.constants.signals[r.signal] || 0);
    return String(code) + "\n" + fs.readFileSync(file, "utf8");
  } catch (e) {
    return "127\n";
  } finally {
    if (dir !== null) {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  }
}
