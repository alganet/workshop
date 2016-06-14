Using Mosai Workshop
====================

The simplest way to run workshop is directly downloading it:

	$ curl -L git.io/workshop.sh | sh -s posit --help

This will download the `posit` module and its dependencies, then run it
with `--help` for you.

You might also [download the workshop.sh file](.) and use it directly:

	$ curl -LO git.io/workshop.sh
	$ chmod +x workshop.sh
	$ ./workshop.sh posit --help

Installing
----------

Execute the `install` module:

	$ curl -L git.io/workshop.sh | sh -s install

Workshop will place itself in userland space acessible from the PATH,
then you can just run:

	$ workshop posit --help
