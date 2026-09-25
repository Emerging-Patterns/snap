// snaprun.start: starts a program and leaves it running, answering with its pid.
//
// The arguments arrive the way exec.c takes them, one string with NULs
// between, and go to execvp as a vector, so no shell sees them. The difference
// is what happens next: nothing is waited for and nothing is read. The child
// gets a session of its own and /dev/null for all three of its streams, so it
// never holds open a pipe someone is reading to the end.
//
// A fork that succeeds says nothing about the exec after it, so the child is
// handed one end of a pipe that closes itself on exec. An exec that fails
// writes a byte down it before the child exits; one that succeeds closes it
// with nothing written. Reading it to the end is the answer: a byte means the
// program could not be started, and the answer is 0, as it is when the fork
// fails.
#include <errno.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <unistd.h>

Term snaprun_start_run(Env e, Term* f, IoWork* w) {
  uint64_t n = 0;
  char* cmd = io_cstr(e, f[0], &n);

  // the NULs between arguments are already terminators, so each argument is
  // its own C string; count them
  size_t argc = 1;
  for (size_t i = 0; i < (size_t)n; i++) {
    if (cmd[i] == '\0') {
      argc++;
    }
  }
  char** argv = malloc((argc + 1) * sizeof(char*));
  size_t at = 0;
  argv[at++] = cmd;
  // an argument starts after every NUL, the last one included: an empty last
  // argument is the empty string at the end, which io_cstr terminates
  for (size_t i = 0; i < (size_t)n; i++) {
    if (cmd[i] == '\0') {
      argv[at++] = cmd + i + 1;
    }
  }
  argv[at] = NULL;

  int told[2];
  int watch = pipe(told) == 0;
  if (watch) {
    fcntl(told[0], F_SETFD, FD_CLOEXEC);
    fcntl(told[1], F_SETFD, FD_CLOEXEC);
  }
  pid_t pid = fork();
  if (pid == 0) {
    setsid();
    int nul = open("/dev/null", O_RDWR);
    dup2(nul, 0);
    dup2(nul, 1);
    dup2(nul, 2);
    if (nul > 2) {
      close(nul);
    }
    execvp(argv[0], argv);
    if (watch) {
      char no = 1;
      ssize_t put = write(told[1], &no, 1);
      (void)put;
    }
    _exit(127);
  }

  // the exec's verdict: end of file when it closed the pipe, a byte when it
  // failed. A child that could not start is reaped here, since nobody else
  // will wait for a pid this answers as 0.
  int started = pid > 0;
  if (watch) {
    close(told[1]);
    if (started) {
      char got;
      ssize_t r;
      do {
        r = read(told[0], &got, 1);
      } while (r < 0 && errno == EINTR);
      if (r > 0) {
        waitpid(pid, NULL, 0);
        started = 0;
      }
    }
    close(told[0]);
  }

  char out[16];
  int on = snprintf(out, sizeof(out), "%d", started ? (int)pid : 0);

  free(argv);
  free(cmd);
  return io_str(e, out, (size_t)on);
}

static void __attribute__((constructor)) snaprun_start_use(void) {
  io_eff(CID(snaprun.start), snaprun_start_run, 0);
}
