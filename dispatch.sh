#!/usr/bin/env workshop

dispatch ()
{
	_ns="${1}"
	_arg="${2:-}"

	if test '_' = '_'${_arg}
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

		_target="${_ns}_option_${_long}"
	elif test "${_arg}" = "-${_short}"
	then
		_target="${_ns}_option_${_short}"
	else
		_target="${_ns}_command_${_long}"
	fi

	set -- "${_target}" "${@:-}"

	"${@:-}"
}
