#!/usr/bin/env workshop

require 'dispatch.sh' 'doc.sh'

posit ()
{
	dispatch 'posit' "${@:-}"
}

posit_command_run ()
{
	find "${1:-${PWD}}" -type f | grep ".md$" | posit_code_elements
}

posit_code_elements ()
{
	while IFS='' read -r _file_path
	do
		doc_command_elements "${_file_path}" "code,h1,h6"
		echo
	done | posit_parse
}

posit_parse ()
{
	_no=0
	_ok=0
	_n="
"

	while IFS='' read -r _element_line
	do
		case "${_element_line%%	*}" in
			'@name' )
				_element_name="${_element_line##*	}"
				;;
			'@href' )
				_element_href="${_element_line##*	}"
				;;
			'@title' )
				_element_title="${_element_line##*	}"
				;;
			'@class' )
				_element_class="${_element_line##*	}"
				;;
			'h6' )
				_element_heading="${_element_line##*	}"
				;;
			'h5' )
				echo "##### ${_element_line##*	}"
				_element_heading="${_element_line##*	}"
				;;
			'h4' )
				echo "#### ${_element_line##*	}"
				_element_heading="${_element_line##*	}"
				;;
			'h3' )
				echo "### ${_element_line##*	}"
				_element_heading="${_element_line##*	}"
				;;
			'h2' )
				echo ""
				echo "## ${_element_line##*	}"
				echo ""
				_element_heading="${_element_line##*	}"
				;;
			'h1' )
				echo ""
				echo "# ${_element_line##*	}"
				echo ""
				_element_heading="${_element_line##*	}"
				;;
			'code' )
				_element="${_element:-}${_element:+${_n}}"
				_element="${_element}${_element_line##*	}"
				;;
			'' )
				if test ! -z "${_element:-}"
				then
					_name="${_element_heading:-}"
					_type="${_element_href:-}"
					case ${_type%% *} in
						'test:module' )
							_no=$(($_no + 1))
							_module="${_element_title}"
							${SHELL:-sh]} \
							<<-SHELL >/dev/null 2>&1 && _e=$? || _e=$?
								set -euf
								path_to_workshop=${workshop_executable}
								unsetopt NO_MATCH  >/dev/null 2>&1 || :
								setopt SHWORDSPLIT >/dev/null 2>&1 || :

								require ()
								{
									_deps="${_deps:-}${_deps:+}\${1}"
								}

								workshop_dependencies="${deps:-}"
								workshop_modules=": workshop ${_module}"
								unset deps

								$(echo "${_element}")

								set -- "${_module:-}"
								. "${workshop_executable}"
							SHELL

							test ${_e} = 0 &&
								echo "ok ${_no}		${_name:-}" ||
								echo "not ok ${_no}	${_name:-}"
							;;
						'test' )
							_no=$(($_no + 1))

							${SHELL:-sh} \
							<<-SHELL >/dev/null 2>&1 && _e=$? || _e=$?
								set -euf
								path_to_workshop=${workshop_executable}
								unsetopt NO_MATCH  >/dev/null 2>&1 || :
								setopt SHWORDSPLIT >/dev/null 2>&1 || :
								$(echo "${_element}")
							SHELL

							test ${_e} = 0 &&
								echo "ok ${_no}		${_name:-}" ||
								echo "not ok ${_no}	${_name:-}"

							test ${_e} = 0 && _ok=$((_ok + 1)) || :
							;;
					esac
					_element=
					_element_name=
					_element_href=
					_element_title=
					_element_class=
				fi
				;;
		esac
	done

	echo "1..${_no}"

	test "${_no}" = "${_ok}"
}
