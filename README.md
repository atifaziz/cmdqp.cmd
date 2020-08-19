# Windows Command Queue Processor

This is a collection of Windows batch scripts to implement a queue (FIFO) of
commands, where each command is designed to be run in sequence.

It uses a single file system directory as the backing store for the command
queue.

The commands that can be put in the queue are themselves Windows batch scripts
with the `.cmd` extension. The queue processor simply runs one command after
another, in their date order.

Once a command has been executed _successfully_, it is renamed by appending
`.bak` to its name. For example, `foobar.cmd` will become `foobar.cmd.bak`.
Any output from the command will be saved to a log file bearing the same name
as the command but with `.log` appended. For example, the log for `foo.cmd`
will be named `foo.cmd.log`.

The queue processor scripts is called `cmdqp.cmd`. Most sub-commands of the
queue processor take `--qdir <DIR>` option where `<DIR>` specifies the queue
directory. If omitted, the queue directory is assumed to be `cmdqp.q` that is
a sub-directory of where `cmdqp.cmd` resides.

If a single command fails, the queue processor stops all further processing
and exits. A file named `lasterror.log` is placed in the queue directory that
can be used for troubleshooting the last failed command.

The command lines shown in this document assume Windows Command Prompt is
your shell and begin with [`call`][call] followed by the batch file name.
For simplcity and brevity, the extension is omitted as the shell does not
require it (inferring it from the `PATHEXT` environment variable). The `call`
portion can also be omitted if you do not care about the exit code to
distinguish between a successful and a failed execution.

To queue a command _safely_, use `qcmd.cmd` as follows:

    call qcmd <QDIR> <CMDPATH>

where `<QDIR>` is queue directory and `<CMDPATH>` is the batch script to
queue. `<CMDPATH>` will be _atomatically_ copied to `<QDIR>`.

The file names of commands (batch files) in the queue must be unique. It is
the responsibility of the caller of `qcmd.cmd` to ensure that the file name
part in `<CMDPATH>` is unique among others in `QDIR`. Appending a randomly
generated [GUID] to the file name is one way to guarantee uniqueness. If not,
the queue processor will exit with a failure.

Running:

    call cmdqp help

shows a summary of sub-commands along with their descriptions:

    Runs command scripts in sequence on a FIFO basis.

    Usage:
        cmdqp help       displays this help
        cmdqp run        run queued tasks once
        cmdqp daemon     run queued tasks forever
        cmdqp list       list the command files of the queue
        cmdqp logs       list the logs
        cmdqp pause      pause before next task (until unpaused)
        cmdqp unpause    unpause
        cmdqp halt       finish current task (if any) then stop

To run all the commands in the queue and exit, run:

    call cmdqp run

To run all the commands in the queue, including any future commands that may
be queued, use the daemon mode:

    call cmdqp daemon

It will run the queue processor in a new and detached shell. To run in the
same session, use the `run` command with the `--forever` flag:

    call cmdqp run --forever

To list all command currently queued for execution, run:

    call cmdqp list

To see the list of log files of executed commands, run:

    call cmdqp logs

To halt the queue processor after it has finished running the current command
in the queue (if it is the case), run:

    call cmdqp halt

This command is useful to gracefully stop the queue processor if, for example,
it was started in the _daemon_ mode.

To temporarily pause the execution of commands in the queue without halting
the queue processor, run:

    call cmdqp pause

The pause remain in effect until you run:

    call cmdqp unpause


[call]: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/call
[GUID]: https://en.wikipedia.org/wiki/Universally_unique_identifier
