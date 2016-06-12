# Undocumented tests used in the prototype

## workshop invokation

[~]:test
	set -- # No Arguments
	. ./workshop

## Running Modules

[~]:file:mymodule.sh
	#!/usr/bin/env workshop

	mymodule ()
	{
		echo 'Hello'
	}

[~]:test
	$ workshop mymodule
	Hello

## Requiring Dependencies

[~]:file:anothermodule.sh
	#!/usr/bin/env workshop

	require 'mymodule'

	anothermodule ()
	{
		mymodule
	}

[~]:test
	$ workshop anothermodule
	Hello

---

## Requiring Circular Dependencies

[~]:file:moduleone.sh
	#!/usr/bin/env workshop

	require 'moduletwo'

	moduleone ()
	{
		echo 'Hello'
		moduletwo
		modulethree
	}


[~]:file:moduletwo.sh
	#!/usr/bin/env workshop

	require 'modulethree'

	moduletwo ()
	{
		echo 'Ola'
	}

[~]:file:modulethree.sh
	#!/usr/bin/env workshop

	require 'moduleone'

	modulethree ()
	{
		echo 'Oi'
	}

[~]:test
	$ workshop moduleone
	Hello
	Ola
	Oi

---


## Downloading Dependencies

[~]:test

	curl ()
	{
		curl_was_called_with="${@:-}"
		cat <<-STUBBED
			#!/usr/bin/env workshop

			missingdep ()
			{
				echo 'Hello' "${curl_was_called_with}"
			}
		STUBBED
	}

	set -- missingdep
	workshop_server=myserver/
	test 'Hello --fail -L myserver/missingdep.sh' = "$(. ./workshop)"


## Module Dependencies Download

[~]:file:somedependency.sh
	#!/usr/bin/env workshop

	require 'moduledep'

	somedependency ()
	{
		moduledep
	}


[~]:test

	curl ()
	{
		curl_was_called_with="${@:-}"
		cat <<-STUBBED
			#!/usr/bin/env workshop

			moduledep ()
			{
				echo 'Hello' "${curl_was_called_with}"
			}
		STUBBED
	}

	set -- somedependency
	workshop_server=myserver/
	test 'Hello --fail -L myserver/moduledep.sh' = "$(. ./workshop)"

## Failure on invalid download

[~]:test

	curl ()
	{
		curl_was_called_with="${@:-}"
		cat <<-STUBBED
			Some 404 Page
		STUBBED
	}

	set +e
	set -- missingfail
	workshop_server=myserver/
	. ./workshop && _code=$? || _code=$?
	test $_code = 127


## Failure on curl error

[~]:test

	curl ()
	{
		curl_was_called_with="${@:-}"
		return 1
	}

	set -- missingerror
	set +e
	workshop_server=myserver/
	. ./workshop && _code=$? || _code=$?
	test $_code = 127

---

## Running Command Tests

[~]:file:welcoming_the_world.md
	###### Welcoming The World

		$ echo Hello World
		Hello World
		$ echo Ola Mundo
		Ola Mundo

---

	$ workshop posit run welcoming_the_world.md
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

	$ workshop posit run functions.md
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

	$ workshop posit run cat_display.md
	ok 1		cat hello.txt
	1..1
