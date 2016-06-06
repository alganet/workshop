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
				;;
			'h4' )
				echo "#### ${_element_line##*	}"
				;;
			'h3' )
				echo "### ${_element_line##*	}"
				;;
			'h2' )
				echo ""
				echo "## ${_element_line##*	}"
				echo ""
				;;
			'h1' )
				echo ""
				echo "# ${_element_line##*	}"
				echo ""
				;;
			'code' )
				_element="${_element:-}${_element:+${_n}}${_element_line##*	}"
				;;
			'' )
				if test ! -z "${_element:-}"
				then
					case "${_element_href:-}" in
						'test:module' )
							_no=$(($_no + 1))
							workshop_executable="${workshop_executable}" ${SHELL:-sh} <<-SHELL && echo "ok ${_no}		${_element_heading:-}" || echo "not ok ${_no}	${_element_heading:-}"
								set -euf
								unsetopt NO_MATCH  >/dev/null 2>&1 || :
								setopt SHWORDSPLIT >/dev/null 2>&1 || :

								require () ( workshop_dependencies="${workshop_dependencies:-}${workshop_dependencies:+}\${1}" )

								$(echo "${_element}")

								set -- "${_element_title:-}"
								. "${workshop_executable}"
							SHELL
							;;
						'test' )
							_no=$(($_no + 1))
							workshop_executable="${workshop_executable}" ${SHELL:-sh} <<-SHELL && echo "ok ${_no}		${_element_heading:-}" || echo "not ok ${_no}	${_element_heading:-}"
								set -euf
								unsetopt NO_MATCH  >/dev/null 2>&1 || :
								setopt SHWORDSPLIT >/dev/null 2>&1 || :
								$(echo "${_element}")
							SHELL
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
}
