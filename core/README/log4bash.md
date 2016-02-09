About 5 years ago I moved from a Java and C++ shop to a team where I was told I could use PHP or bash. I chose bash over PHP any day. But I could not find a decent log function! So I made one.
Simply stuffing your code with echo statements hardly counts as logging.

1. It prevents you from being able to return values to the caller of a function
2. It makes it hard to manage log levels, dialing up when debugging, dialing down for prod

But the good news is this log function is easy to use!

**Features:**
*	Allows multiple logs in the same script
*	Allows each of those logs to have set log levels (0-5)
*	Allows you to push messages to a log file, syslog, or echo them out depending on your need
*	Automatically pushes critical error to sysloger 
*	Provides a bash like stack trace function for debugging complex scripts
*	Allows you to specify individual files or a single combined log file across multiple scripts
*	Allows you to automatically tag log entries with log level, pid, data/time, and custom notation for calling function
*	Allows you to produce neatly organized multi line log entries even if those entries are not pushed in the same block of code. 
*	Automatically creates log directories / files on initial deploy
*	It is incredibly easy to use

