#!/usr/bin/env workshop

require 'dispatch' 'doc'

# posit document test runner
#
# Extracts and runs shell script tests from Markdown code blocks.
#
posit ()
{
	dispatch 'posit' "${@:-}"
}

# Runs tests on all Markdown files found in the given path
posit_command_run ()
{
	find "${1:-$(pwd)}" -type f | sort | grep ".md$" | posit_run_multi
}

posit_run_multi ()
{
	while IFS='' read -r _file_path
	do
		doc_command_elements "${_file_path}" "code,h1,h2,h3,h4,h5,h6"
		echo
	done | posit_run
}

posit_run ()
{
	_errmode="$(set +o)"
	_no=0
	_ok=0
	_n="
"
	_current_dir="$(pwd)"
    _temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/posit.XXXXXX" 2>/dev/null)"
    if test -z "${_temp_dir}"
	then
		_temp_dir="${TMPDIR:-/tmp}/posit."$(od -An -N2 -i /dev/random)
	    mkdir -m 700 "${_temp_dir}"
	fi
	cd "${_temp_dir}"  || exit
	cp "${workshop_executable}" "./workshop"
	chmod +x "./workshop"
	while IFS='' read -r _element_line
	do
		case "${_element_line%%	*}" in
			'@href' )
				_element_href="${_element_line#*	}"
				;;
			'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6' )
				_element_heading="${_element_line#*	}"
				;;
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
						_no=$((_no + 1))

						set +e
						_test_out="$(: | posit_bootstrap_command)"
						_e=$?
						${_errmode}

						posit_report

						_current_prompt=
						_element=
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
			_element="$(printf %s "${_element}")"
			_on_prompt="$(printf %s "${_on_prompt}")"
			_no=$((_no + 1))

			set +e
			_test_out="$(: | posit_bootstrap_command)"
			_e=$?
			${_errmode}

			posit_report

			_on_prompt=
			_element=
			_element_href=
		fi

		if test ! -z "${_element:-}"
		then
			_name="${_element_heading:-}"
			_namespace="${_element_href:-}"
			_type="${_namespace%%:*}"
			_value="${_namespace##*:}"
			_file="$(basename "${_value}")"
			case ${_type%% *} in
				'file' )
					printf %s\\n "${_element}" > "${_file}"
					;;
				'test' )
					_no=$((_no + 1))

					set +e
					_test_out="$(: | posit_bootstrap_test)"
					_e=$?
					${_errmode}

					posit_report
					;;
			esac
			_element=
			_element_href=
		fi
	done
	cd "${_current_dir}" || exit
	rm -Rf "${_temp_dir}"

	echo "1..${_no}"
	test "${_no}" = "${_ok}"
	exit $?
}

posit_report ()
{
	if test ${_e} = 0
	then
		echo "ok ${_no}		${_name:-}"
	else
		echo "not ok ${_no}	${_name:-}"
	fi

	if test ${_e} = 0
	then
		_ok=$((_ok + 1))
	else
		echo "${_test_out:-}" | sed 's/^/#	/'
	fi
}

posit_bootstrap_command ()
{
	${SHELL} <<-EXTERNALSHELL 2>&1
		unsetopt NO_MATCH  >/dev/null 2>&1 || :
		setopt SHWORDSPLIT >/dev/null 2>&1 || :
		set -x
		set +e
		_output="\$(
			PATH="\${PATH}:." \
			workshop_path="\$(pwd):${workshop_path:-}" \
			workshop_unsafe=1 \
			workshop_executable="${workshop_executable}" \
			workshop_lib="\$(pwd)" \
			${_on_prompt}
		)"
		_code=\$?
		test \${_code} = 0 &&
			test _"\${_output}" = _'${_element}'
	EXTERNALSHELL
}

posit_bootstrap_test ()
{
	${SHELL} <<-EXTERNALSHELL 2>&1
		unsetopt NO_MATCH  >/dev/null 2>&1 || :
		setopt SHWORDSPLIT >/dev/null 2>&1 || :
		set -x
		set +e
		PATH="\${PATH}:."
		workshop_unsafe=1
		workshop_path="\$(pwd):${workshop_path:-}"
		workshop_executable="${workshop_executable}"
		workshop_lib="\$(pwd)"
		$(printf %s\\n "${_element}")

		exit $?
	EXTERNALSHELL

}
