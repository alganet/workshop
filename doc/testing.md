# Undocumented tests used in the prototype

## Running Command Tests

[~]:file:welcoming_the_world.md
	###### Welcoming The World

		$ echo Hello World
		Hello World
		$ echo Ola Mundo
		Ola Mundo

---

	$ workshop posit.sh run welcoming_the_world.md
	ok 1		echo Hello World
	ok 2		echo Ola Mundo
	1..2

## Running Test Scripts

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


## Using Test Fixtures

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

---

	$ workshop posit.sh run cat_display.md
	ok 1		cat hello.txt
	1..1
