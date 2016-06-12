# Testing with workshop

workshop testing and documentation are one and the same.

This document defines a reusable testing structure that works on top
of documentation. It provides automatic test runs on top of code
extracted from Markdown documents.

## Testing Format

workshop testing format is designed to be compliant with Markdown.

Indented or fenced code blocks should be written as tests, yet
self-sufficient enough to be copied and manually executed as a sample.

Since there is no nesting on code blocks, workshop Markdown parser
should be straightforward and fast, able to extract and run the
appropriate tests from multiple documents at once.

### Simple Tests

The simplest test model represents a series of shell commands being
executed. Filesystem is preserved between runs.

To write a test, create a Markdown code block:

[~]:file:welcoming_the_world.md
	###### Welcoming The World

		$ echo Hello World
		Hello World
		$ echo Ola Mundo
		Ola Mundo

When running, each command should yield a test unit. Output should be
TAP compliant:

	$ workshop posit.sh run welcoming_the_world.md
	ok 1		echo Hello World
	ok 2		echo Ola Mundo
	1..2

### Test Fixtures

You can set up files to be used on tests. For that, add a code block
with the special `[~]:file` directive. The directive is invisible
when converting Markdown to HTML, making documents more clear:

[~]:file:cat_display.md
	###### Displaying a file with cat

	Given a simple file with two lines:

	[~]:file:hello.txt
		Hello
		World

	Running `cat` displays it:

		$ cat hello.txt
		Hello
		World

Run it as normal:

	$ workshop posit.sh run cat_display.md
	ok 1		cat hello.txt
	1..1

### Test Scripts

Instead of just testing individual commands, you might test more
elaborate scripts:

[~]:file:functions.md
	###### Creating Functions

	[~]:test
		my_function ()
		{
			echo 'Hello World'
		}

		test 'Hello World' = "$(my_function)"

---

	$ workshop posit.sh run functions.md
	ok 1		Creating Functions
	1..1

