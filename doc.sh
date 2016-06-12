#!/usr/bin/env workshop

require 'dispatch.sh' 'parsed.sh'

doc ()
{
	dispatch 'doc' "${@:-README.md}"
}


doc_dispatched ()
{
	doc_command_show "${@:-README.md}"
}

doc_command_show ()
{
	doc_command_elements "${@:-}" | parsed doc_parse_draw
}

doc_command_elements ()
{
	_file="${1:-README.md}"
	shift

	( cat "${_file}"; echo ) |
		parsed doc_parse_elements | doc_filter "${@:-}"
}

doc_filter ()
{
	_selector="${1:-*}"
	_meta=''
	_n="
"

	while IFS='' read -r _line
	do
		case "${_line%%	*}" in
		'@name'|'@href'|'@title'|'@class' )
			_meta="${_meta:-}${_meta:+${_n}}${_line}"
			;;
		[a-z]* )
			if test '*' = "${_selector}"
			then
				_element=1
				test -z "${_meta}" || echo "${_meta}
"
				echo "${_line}"
			else
				_ifs="${IFS}"
				IFS=','
				_current="${_line%%	*}"
				for _sel in ${_selector}
				do
					if test "${_sel}" = "${_current}"
					then
						_element=1
						test -z "${_meta}" || echo "${_meta}
	"
						echo "${_line}"
					fi
				done
				IFS="${_ifs}"
			fi
			_meta=
			;;
		'' )
			test -z "${_element:-}" || echo "${_line}"
			_element=
			;;
		esac
	done
}

doc_parse_tokens ()
{
	_h1='# '
	_h2='## '
	_h3='### '
	_h4='#### '
	_h5='##### '
	_h6='###### '
	_anychar='.'
	_blank='$'
	_indent='    '
	_tabbed="$(printf '\t')"
	_ticked='```'
	_tilded='~~~'
	_title_open=" *[(\"]"
	_title_end="[)\"] *"
	_title_val="[^)\"]*"
	_title="${_title_open}${_title_val}${_title_end}"
	_link_val="[^]]*"
	_link_open='\['
	_link_close='\]:'
	_link_until_open="[^(\"]*"
	_link="${_link_open}${_link_val}${_link_close}"
	_bold="$(tput 'bold' || :)"
	_rev="$(tput 'rev' || :)"
	_dim="$(tput 'dim' || :)"
	_reset="$(tput 'sgr0' || :)" # Reset last to avoid debug color bleed
}

doc_parse_draw ()
{
	doc_parse_tokens

	context 'list'
		ifmatch "${_blank}" enter 'element_end'
		ifmatch "@${_anychar}*	" enter 'meta'
		ifmatch "${_anychar}*	" enter 'element'
		print
		next
		ifend quit
		enter 'list'

	context 'element'
		ifmatch "h1	" enter 'h1'
		ifmatch "h2	" enter 'h2'
		ifmatch "@title	" enter 'meta'
		ifmatch "code	" enter 'code'
		replace "${_anychar}*	" ''
		print
		next
		enter 'list'

	context 'h1'
		replace "h1	" ''
		replace "\(.*\)$" "${_bold}\1${_reset}"
		hold
		get
		replace '........' ''
		replaceall 'h1char' '='
		replace "\(.*\)$" "${_dim}\1${_reset}"
		keep
		get
		print
		next
		enter 'list'

	context 'h2'
		replace "h2	" ''
		replace "\(.*\)$" "${_bold}\1${_reset}"
		hold
		get
		replace '........' ''
		replaceall 'h2char' '-'
		replace "\(.*\)$" "${_dim}\1${_reset}"
		keep
		get
		print
		next
		enter 'list'

	context 'code'
		replace "code	" ''
		enter 'codepad'

	context 'codepad'
		replace '	' '    '
		ifnotmatchall '.\{72\}' enter 'codereplace'
		enter 'codepaint'

	context 'codereplace'
		replace '$' ' '
		enter 'codepad'

	context 'codepaint'
		replace ".*" "${_dim}${_rev}    ${_reset}${_rev}&${_reset}"
		print
		next
		enter 'list'

	context 'meta'
		next
		ifmatch "${_blank}" enter 'meta'
		enter 'list'

	context 'element_end'
		print
		next
		enter 'list'
}

doc_parse_elements ()
{
	doc_parse_tokens
	fence ()
	{
		context "${1}"
			remove "${2}"
			ifmatch "${_anychar}"  enter "${1}_attr"
			next
			ifmatch "${2}"  enter "${1}_out"
			ifmatch "${_anychar}" enter "${1}_inside"
			ifmatch "${_blank}" enter "${1}_inside"
			enter "${1}"

		context "${1}_attr"
			append
			line '@class'
			ifmatch "${2}"  enter "${1}_out"
			ifmatch "${_anychar}" enter "${1}_inside"
			ifmatch "${_blank}" enter "${1}_inside"
			enter "${1}"

		context "${1}_inside"
			line "code" "${_anychar}"
			ifmatch "${2}"  enter "${1}_out"
			ifmatch "${_anychar}" enter "${1}_inside"
			ifmatch "${_blank}" enter "${1}_inside"
			enter "${1}"

		context "${1}_out"
			append
			delete
			enter 'text'
	}

	heading ()
	{
		context "${1}"
			remove "${2}"
			hold
			next
			ifmatch "${_blank}" enter "${1}blank"
			get
			append
			line "${1}"
			enter 'text'

		context "${1}blank"
			get
			append
			line "${1}"
			enter 'text'
	}

	blocks ()
	{
		ifmatch "${_h1}"      enter "h1"
		ifmatch "${_h2}"      enter "h2"
		ifmatch "${_h3}"      enter "h3"
		ifmatch "${_h4}"      enter "h4"
		ifmatch "${_h5}"      enter "h5"
		ifmatch "${_h6}"      enter "h6"
		ifmatch "${_blank}"   enter "blank"
		ifmatch "${_indent}"  enter "indent"
		ifmatch "${_tabbed}"  enter "tabbed"
		ifmatch "${_ticked}"  enter "ticked"
		ifmatch "${_tilded}"  enter "tilded"
		ifmatch "${_link}"    enter "ref"
	}


	context 'text'
		blocks
		ifmatch "${_anychar}" enter 'paragraph'
		ifend quit
		enter 'text'

	context 'ref'
		remove "${_link_open}"
		detach '@name' "${_link_val}"
		remove "${_link_close}"
		detach '@href' "${_link_until_open}"
		ifmatch "${_title}" enter 'reftitle'
		append
		enter 'text'

	context 'reftitle'
		remove "${_title_open}"
		detach '@title' "${_title_val}"
		remove "${_title_end}"
		append
		enter 'text'

	context 'blank'
		delete
		enter 'text'

	context 'paragraph'
		line 'text'
		ifmatch "${_blank}" enter 'paragraph'
		blocks
		enter 'paragraph'

	context 'indent'
		grind 'code' "${_indent}"
		ifmatch "${_blank}" enter 'indent'
		ifmatch "${_indent}" enter 'indent'
		prepend
		blocks
		enter 'text'

	context 'tabbed'
		grind 'code' "${_tabbed}"
		ifmatch "${_blank}" enter 'tabbed'
		ifmatch "${_tabbed}" enter 'tabbed'
		prepend
		blocks
		enter 'text'

	heading "h1" "${_h1}"
	heading "h2" "${_h2}"
	heading "h3" "${_h3}"
	heading "h4" "${_h4}"
	heading "h5" "${_h5}"
	heading "h6" "${_h6}"
	fence "ticked" "${_ticked}"
	fence "tilded" "${_tilded}"

}
