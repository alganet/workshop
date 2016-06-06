# **workshop** Internal Tests

**workshop** is distributed as an executable for convenience. It can
be used as a library though. The **posit** tool, part of the workshop
library, also uses workshop to encapsulate each test run.

Inside tests, you can also start workshop instances and test their
behavior.

###### Dispatching workshop with no arguments

Workshop will gracefully do nothing with zero or just one parameter:

[~]:test
	. "${workshop_executable}"

	workshop && workshop "${PWD}"

###### Dispatching an existing module

You can use workshop as a module loader. It will look in his own
folder for sibling modules to require.


[~]:test
	. "${workshop_executable}"

	myfunc_dispatched () ( echo 'Hello' )

	test Hello = $(workshop "${PWD}" dispatch.sh myfunc)


###### Dispatching missing modules

Missing modules try to be downloaded from the internet. On error,
workshop will exit.

[~]:test
	. "${workshop_executable}"

	curl () ( return 1 )

	test Fail = $(workshop "${PWD}" curl_fail_stub.sh || echo Fail)

###### Changing the default server

[~]:test
	. "${workshop_executable}"

	curl ()
	{
		echo "#!/usr/bin/env workshop"
		echo "curl_params_mock () ( echo '${*:-}' )"
	}

	test '--fail -L myserver/curl_params_mock.sh' = "$(
		cd /tmp
		workshop_server='myserver/'
		workshop "${PWD}" curl_params_mock.sh
	)"

