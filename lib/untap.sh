#!/usr/bin/env workshop

require 'dispatch'

untap ()
{
	dispatch 'untap' "${@:-}"
}

untap_command_merge ()
{
	cat | untap_recount
}

untap_command_matrix ()
{
	cat | untap_matrix
}

untap_recount ()
{
	_no=0

	while read -r _tap_line; do

		_tap_status="${_tap_line%% *}"
		case ${_tap_status} in
			'ok' | 'not ok' )
				_no=$((_no + 1))
				printf '%s' "${_tap_status} "
				_tap_test="${_tap_line#* }"
				_tap_desc="${_tap_test#*	}"
				printf '%s' "${_no}	 "
				printf '%s\n' "${_tap_desc# *}"
				;;
			* )
				continue
				;;
		esac
	done

	echo "1..${_no}"
}


untap_matrix ()
{
	_tests=""

	while read -r _tap_line; do
		_tap_status="${_tap_line%% *}"
		_tap_status="${_tap_status%%	*}"
		_tap_test="${_tap_line#* }"
		_tap_number="${_tap_test%%	*}"
		case ${_tap_status} in
			'ok' )
				_tests="${_tests}${_tap_number}-${_tap_status} "
				;;
			'not' )
				printf '%s\n' "${_tap_line}"
				_tests="${_tests}${_tap_number}-${_tap_status} "
				;;
			'#' )
				printf '%s\n' "${_tap_line}"
				;;
			* )
				continue
				;;
		esac
	done

	printf '%s\n' ${_tests} | sort -n | uniq
}
