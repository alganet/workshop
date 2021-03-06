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
	flash "Finding tests..."
	find "${1:-$(pwd)}" -type f | sort | grep ".md$" | posit_run_multi
}

posit_option_help ()
{
	cat <<-USAGE
	Usage: posit [COMMAND]
	Extracts and runs shell script tests from Markdown code blocks.

	Commands: run  PATH  Runs all files specified in the given path
	USAGE
}

posit_run_multi ()
{
	flash "Parsing Test Files..."
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
    _temp_dir="$(tempdir posit)"
	cd "${_temp_dir}"  || exit
	cp "${workshop_executable}" "./workshop"
	chmod +x "./workshop"
	flash
	while IFS='' read -r _element_line
	do
		case "${_element_line%%	*}" in
			'@href' )
				_element_href="${_element_line#*	}"
				;;
			'h1' | 'h2' | 'h3' | 'h4' | 'h5' | 'h6' )
				_element_heading="${_element_line#*	}"
				_name="${_element_heading}"
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

						posit_report "${_e}"

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


		_namespace="${_element_href:-}"
		_type="${_namespace%%:*}"
		_value="${_namespace##*:}"

		case ${_type%% *} in
			'folder' )
				mkdir -p "${_temp_dir}/${_value}"
				cp -R "${_current_dir}/${_value%/}" "${_temp_dir}/"
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

			posit_report "${_e}"

			_on_prompt=
			_element=
			_element_href=
		fi

		if test ! -z "${_element:-}"
		then
			_namespace="${_element_href:-}"
			_type="${_namespace%%:*}"
			_value="${_namespace##*:}"
			_file="$(basename "${_value}")"
			case ${_type%% *} in
				'file' )
					printf %s\\n "${_element}" > "${_file}"
					;;
				'test')
					_no=$((_no + 1))

					set +e
					_test_out="$(: | posit_bootstrap_test)"
					_e=$?
					${_errmode}

					posit_report_${_type%% *} "${_e}"
					;;
				'show')
					_no=$((_no + 1))

					set +e
					posit_bootstrap_show
					_e=$?
					${_errmode}

					posit_report_${_type%% *} "${_e}"
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
}


posit_report_test ()
{
	posit_report "${@:-}"
}

posit_report ()
{
	if test ${1} = 0
	then
		echo "ok	${_no}	${_name:-}"
	else
		echo "not ok	${_no}	${_name:-}"
	fi

	if test ${1} = 0
	then
		_ok=$((_ok + 1))
	else
		echo "${_test_out:-}" | sed 's/^/#	/'
	fi
}

posit_report_show ()
{
	posit_report "${@:-}" >/dev/null; echo "${_test_out:-}"
}

posit_bootstrap_command ()
{
	${posit_shell:-/usr/bin/env sh} <<-EXTERNALSHELL 2>&1
		unsetopt NO_MATCH  >/dev/null 2>&1 || :
		setopt SHWORDSPLIT >/dev/null 2>&1 || :
		set -x
		set +e
		test _"\$(
			PATH=".:${PATH}" \
			workshop_path="\$(pwd):${workshop_path:-}" \
			workshop_unsafe=1 \
			workshop_executable="${workshop_executable}" \
			workshop_lib="\$(pwd)" \
			${_on_prompt}
		)" = _"${_element}" || exit 1
	EXTERNALSHELL
}

posit_bootstrap_test ()
{
	PATH=".:${PATH}" \
	workshop_unsafe=1 \
	workshop_path="$(pwd):${workshop_path:-}" \
	workshop_executable="${workshop_executable}" \
	workshop_lib="$(pwd)" \
	${posit_shell:-/usr/bin/env sh} <<-EXTERNALSHELL 2>&1
		unsetopt NO_MATCH  >/dev/null 2>&1 || :
		setopt SHWORDSPLIT >/dev/null 2>&1 || :
		set -x
		set +e
		$(printf '%s\n' "${_element}")

		exit \$?
	EXTERNALSHELL

}


posit_bootstrap_show ()
{
	PATH=".:${PATH}" \
	workshop_unsafe=1 \
	workshop_path="$(pwd):${workshop_path:-}" \
	workshop_executable="${workshop_executable}" \
	workshop_lib="$(pwd)" \
	${posit_shell:-/usr/bin/env sh} <<-EXTERNALSHELL 2>&1
		unsetopt NO_MATCH  >/dev/null 2>&1 || :
		setopt SHWORDSPLIT >/dev/null 2>&1 || :
		set +e
		$(printf '%s\n' "${_element}")

		exit \$?
	EXTERNALSHELL

}

