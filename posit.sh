#!/usr/bin/env workshop

require 'dispatch' 'doc'

# Runs tests inside Markdown code blocks
posit ()
{
	dispatch 'posit' "${@:-}"
}

# Runs tests for a specified path
posit_command_run ()
{
	find "${1:-${PWD}}" -type f | sort | grep ".md$" | posit_parse_multi
}

# Runs tests for each path provided in the stdin
posit_parse_multi ()
{
	while IFS='' read -r _file_path
	do
		posit_parse "${_file_path}"
		echo
	done | posit_run
}

# Parses a Markdown file into an encoded doc stream of its elements
posit_parse ()
{
	doc_command_elements "${1}" "code,h1,h2,h3,h4,h5,h6"
}

# Runs tests for any encoded doc stream of Markdown elements
posit_run ()
{
	_errmode="$(set +o)"
	_no=0
	_ok=0
	_n="
"
	_current_dir="$(pwd)"
	mkdir -p /tmp/posit
	cd /tmp/posit
	while IFS='' read -r _element_line
	do
		case "${_element_line%%	*}" in
			# The name inside a link reference
			'@name' )
				_element_name="${_element_line#*	}"
				;;
			# The actual link reference
			'@href' )
				_element_href="${_element_line#*	}"
				;;
			# A heading
			'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6' )
				_element_heading="${_element_line#*	}"
				;;
			# A Code element
			'code' )
				_raw_line="${_element_line#*	}"
				_after_prompt="${_raw_line#*$ }"
				_current_prompt=

				if test ! -z "${_on_prompt:-}"
				then
					_current_prompt="${_on_prompt}"
				fi

				if test "$ ${_after_prompt}" = "${_raw_line}"
				then
					if test ! -z "${_on_prompt:-}"
					then
						_name="${_current_prompt:-}"
						_no=$(($_no + 1))

						set +e
						_test_out="$(posit_bootstrap_command)"
						_e=$?
						${_errmode}

						posit_test_report \
						"${_e}" "${_no}" "${_name:-}" "${_test_out}"

						_current_prompt=
						_element=
						_element_name=
						_element_href=
					fi
					_on_prompt="${_after_prompt}"
				else
					_element="${_element:-}${_element:+${_n}}"
					_element="${_element}${_raw_line}"
				fi

				;;
			'' )
				_end_of_element=1
				;;
		esac

		test ! -z "${_end_of_element:-}" || continue

		_end_of_element=
		if test ! -z "${_on_prompt:-}"
		then
			_name="${_on_prompt:-}"
			_element="$(
				printf %s "${_element}" |
				sed 's/^[ \t]*//;s/[ \t]*$//'
			)"
			_on_prompt="$(
				printf %s "${_on_prompt}" |
				sed 's/^[ \t]*//;s/[ \t]*$//'
			)"
			_no=$(($_no + 1))

			set +e
			_test_out="$(posit_bootstrap_command)"
			_e=$?
			${_errmode}

			posit_test_report \
			"${_e}" "${_no}" "${_name:-}" "${_test_out}"

			_on_prompt=
			_element=
			_element_name=
			_element_href=
		fi

		if test ! -z "${_element:-}" && test "${_element_name}" = '~'
		then
			_name="${_element_heading:-}"
			_namespace="${_element_href:-}"
			_type="${_namespace%%:*}"
			_value="${_namespace##*:}"
			case ${_type%% *} in
				'file' )
					printf %s\\n "${_element}" > "$(basename "${_value}")"
					;;
				'test' )
					_no=$(($_no + 1))

					set +e
					_test_out="$(posit_bootstrap_test)"
					_e=$?
					${_errmode}

					posit_test_report \
					"${_e}" "${_no}" "${_name:-}" "${_test_out}"
			esac
			_element=
			_element_name=
			_element_href=
		fi
	done
	cd "${_current_dir}"

	echo "1..${_no}"
	test "${_no}" = "${_ok}"
	exit $?
}

posit_test_report ()
{
	test ${1} = 0 &&
		echo "ok ${2}		${3:-}" ||
		echo "not ok ${2}	${3:-}"

	test ${1} = 0 && _ok=$(($_ok + 1)) ||
		echo "${4:-}" | tail -n 100
}

# Runs an external command list test
posit_bootstrap_command ()
{
	${SHELL} <<-EXTERNALSHELL 2>&1
		set -x
		workshop ()
		{
			set -- "\${@:-}"
			unset -f workshop
			. "\${path_to_workshop}"
		}
		workshop_path="${workshop_path:-}"
		path_to_workshop="${workshop_executable}"
		workshop_executable="${workshop_executable}"
		unsetopt NO_MATCH  >/dev/null 2>&1 || :
		setopt SHWORDSPLIT >/dev/null 2>&1 || :
		_output="\$(${_on_prompt})"
		test $? = 0 &&
			test _"\${_output}" = _'${_element}'
	EXTERNALSHELL
}

# Runs an external script test
posit_bootstrap_test ()
{
	${SHELL} <<-EXTERNALSHELL 2>&1
		set -x
		path_to_workshop="${workshop_executable}"
		workshop_executable="${workshop_executable}"
		unsetopt NO_MATCH  >/dev/null 2>&1 || :
		setopt SHWORDSPLIT >/dev/null 2>&1 || :
		$(printf %s\\n "${_element}")
	EXTERNALSHELL

}
