#!/usr/bin/env workshop

require 'dispatch.sh' 'doc.sh'

posit ()
{
	dispatch 'posit' "${@:-}"
}

posit_command_run ()
{
	find "${1:-${PWD}}" -type f | sort | grep ".md$" | posit_code_elements
}

posit_code_elements ()
{
	while IFS='' read -r _file_path
	do
		doc_command_elements "${_file_path}" "code,h1,h2,h3,h4,h5,h6"
		echo
	done | posit_parse
}

posit_parse ()
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
			'@name' )
				_element_name="${_element_line#*	}"
				;;
			'@href' )
				_element_href="${_element_line#*	}"
				;;
			'@title' )
				_element_title="${_element_line#*	}"
				;;
			'@class' )
				_element_class="${_element_line#*	}"
				;;
			'h6' )
				_element_heading="${_element_line#*	}"
				;;
			'h5' )
				echo "##### ${_element_line#*	}"
				_element_heading="${_element_line#*	}"
				;;
			'h4' )
				echo "#### ${_element_line#*	}"
				_element_heading="${_element_line#*	}"
				;;
			'h3' )
				echo "### ${_element_line#*	}"
				_element_heading="${_element_line#*	}"
				;;
			'h2' )
				echo ""
				echo "## ${_element_line#*	}"
				echo ""
				_element_heading="${_element_line#*	}"
				;;
			'h1' )
				echo ""
				echo "# ${_element_line#*	}"
				echo ""
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
						_no=$(($_no + 1))

						set +e
						_test_out="$(posit_bootstrap_command)"
						_e=$?
						${_errmode}

						test ${_e} = 0 &&
							echo "ok ${_no}		${_name:-}" ||
							echo "not ok ${_no}	${_name:-}"

						test ${_e} = 0 && _ok=$(($_ok + 1)) ||
							echo "${_test_out:-}" | tail -n 100

						_current_prompt=
						_element=
						_element_name=
						_element_href=
						_element_title=
						_element_class=
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
				sed 's/^[	 ]*//;s/[	 ]*$//'
			)"
			_on_prompt="$(
				printf %s "${_on_prompt}" |
				sed 's/^[	 ]*//;s/[	 ]*$//'
			)"
			_no=$(($_no + 1))

			set +e
			_test_out="$(posit_bootstrap_command)"
			_e=$?
			${_errmode}

			test ${_e} = 0 &&
				echo "ok ${_no}		${_name:-}" ||
				echo "not ok ${_no}	${_name:-}"

			test ${_e} = 0 && _ok=$(($_ok + 1)) ||
				echo "${_test_out:-}" | tail -n 100

			_on_prompt=
			_element=
			_element_name=
			_element_href=
			_element_title=
			_element_class=
		fi

		if test ! -z "${_element:-}"
		then
			_name="${_element_heading:-}"
			_namespace="${_element_href:-}"
			_type="${_namespace%%:*}"
			_value="${_namespace##*:}"
			case ${_type%% *} in
				'file' )
					printf %s\\n "${_element}" > "$(basename "${_value}")"
					;;
				'module' )
					if test "${_value}" = 'test'
					then
						_no=$(($_no + 1))
						_module="${_element_title}"
						set +e
						_test_out="$(posit_bootstrap_module)"
						_e=$?
						${_errmode}

						test ${_e} = 0 &&
							echo "ok ${_no}		${_name:-}" ||
							echo "not ok ${_no}	${_name:-}"

						test ${_e} = 0 && _ok=$(($_ok + 1)) ||
							echo "${_test_out:-}" | tail -n 100
						fi
					;;
				'test' )
					_no=$(($_no + 1))

					set +e
					_test_out="$(posit_bootstrap_test)"
					_e=$?
					${_errmode}

					test ${_e} = 0 &&
						echo "ok ${_no}		${_name:-}" ||
						echo "not ok ${_no}	${_name:-}"

					test ${_e} = 0 && _ok=$(($_ok + 1)) ||
						echo "${_test_out:-}" | tail -n 100
					;;
			esac
			_element=
			_element_name=
			_element_href=
			_element_title=
			_element_class=
		fi
	done
	cd "${_current_dir}"

	echo "1..${_no}"
	test "${_no}" = "${_ok}"
	exit $?
}

posit_bootstrap_command ()
{
	sh <<-EXTERNALSHELL 2>&1
		set -x
		workshop ()
		{
			. "\${path_to_workshop}" "\${@:-}"
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

posit_bootstrap_module ()
{
	sh <<-EXTERNALMODULE 2>&1
		path_to_workshop="${workshop_executable}"
		workshop_executable="${workshop_executable}"
		unsetopt NO_MATCH  >/dev/null 2>&1 || :
		setopt SHWORDSPLIT >/dev/null 2>&1 || :

		require ()
		{
			_deps="${_deps:-}${_deps:+}\${1}"
		}

		workshop_dependencies="${deps:-}"
		workshop_modules=": workshop ${_module}"
		unset deps
		set -x

		$(printf %s\\n "${_element}")

		set -- "${_module:-}"
		. "${workshop_executable}"
	EXTERNALMODULE

}

posit_bootstrap_test ()
{
	sh <<-EXTERNALSHELL 2>&1
		set -x
		path_to_workshop="${workshop_executable}"
		workshop_executable="${workshop_executable}"
		unsetopt NO_MATCH  >/dev/null 2>&1 || :
		setopt SHWORDSPLIT >/dev/null 2>&1 || :
		$(printf %s\\n "${_element}")
	EXTERNALSHELL

}
