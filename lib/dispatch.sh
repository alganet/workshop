#!/usr/bin/env workshop

# dispatches command line arguments and options to functions
dispatch ()
{
	_ns="${1}"
	_arg="${2:-}"

	if test "" = "${_arg}"
	then
		return 0
	fi

	_short="${_arg#*-}"
	_long="${_short#*-}"

	shift 2

	if test "${_arg}" = "--${_long}"
	then
		_long_name="${_long%%=*}"

		if test "${_long}" != "${_long_name}"
		then
			_long_value="${_long#*=}"
			_long="${_long_name}"
			set -- "${_long_value}" "${@:-}"
		fi

		_target="${_ns}${dispatch_option:-_option_}${_long}"
	elif test "${_arg}" = "-${_short}"
	then
		_target="${_ns}_${dispatch_option:-option}_${_short}"
	elif test -z "${dispatch_opts_only:-}"
	then
		_target="${_ns}_${dispatch_command:-command}_${_long}"
	fi

	set -- "${_target:-:}" "${@:-}"

	if test -z "${dispatch_name:-}"
	then
		"${@:-}"
	else
		echo "${@:-}"
	fi
}
