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

untap_command_compare ()
{
	cat | untap_compare "${@:-}"
}

untap_recount ()
{
	_no=0

	while read -r _tap_line; do

		_tap_status="${_tap_line%%	*}"
		case ${_tap_status} in
			'ok' | 'not ok' )
				_no=$((_no + 1))
				printf '%s' "${_tap_status}	"
				_tap_test="${_tap_line#*	}"
				_tap_title="${_tap_test##*	}"
				printf '%s' "${_no}	"
				printf '%s\n' "${_tap_title}"
				;;
			* )
				printf %s\\n "${_tap_line}"
				continue
				;;
		esac
	done

	echo "1..${_no}"
}


untap_compare ()
{
	_tests=""
	_failures=""
	_index=0

	while read -r _tap_line; do
		_tap_status="${_tap_line%%	*}"
		_tap_test="${_tap_line#*	}"
		_tap_number="${_tap_test%%	*}"
		_tap_title="${_tap_test##*	}"
		case ${_tap_status} in
			'ok' | 'not ok' )
				if test "${_tap_number}" = '1'
				then
					_index=$((_index + 1))
					_name="${1:-${_index}}"
					shift || :
				fi
				echo "# [${_name}]	${_tap_line}"
				;;
			* )
				;;
		esac
		if test "${_tap_status}" = 'not ok'
		then
			_tests="$(printf %s\\n%s \
				"${_tests}" \
				"${_tap_status}	${_tap_number}	${_tap_title}"
			)"
			_failures="$(printf %s\\n%s \
				"${_failures}" \
				"#fail	${_tap_number}	${_tap_title} [${_name}]"
			)"
		elif test "${_tap_status}" = 'ok'
		then
			_tests="$(printf %s\\n%s \
				"${_tests}" \
				"${_tap_status}	${_tap_number}	${_tap_title}"
			)"
		fi
	done

	(
		printf %s\\n "${_tests}" |
			sed '/^[ 	]*$/ d' |
			sort -k2 -t "$(printf \\t)"     |
			sort -k2 -t "$(printf \\t)" -u  |
			sort -n -k2 -t "$(printf \\t)"

		printf %s\\n "${_failures}" |
			sed '/^[ 	]*$/ d' |
			sort -k2 -t "$(printf \\t)"
	) | untap_recount

	test -z "${_failures}"
}
