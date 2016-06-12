#!/usr/bin/env workshop

require 'dispatch' 'parsed'

# Parses Markdown documents to a element list
doc ()
{
	dispatch 'doc' "${@:-README.md}"
}

# Displays a Markdown document friendly to terminal output
doc_command_show ()
{
	doc_command_elements "${@:-}" | parsed doc_parse_draw
}

# Returns a parsed list of elements from a Markdown file
doc_command_elements ()
{
	_file="${1:-README.md}"
	shift

	( cat "${_file}"; echo ) |
		parsed doc_parse_elements | doc_filter "${@:-}"
}

# Filters out elements from a element list
doc_filter ()
{
	_selector="${1:-*}"
	_meta=''
	_n="
"

	while IFS='' read -r _line
	do
		case "${_line%%	*}" in
			# Meta elements not visible
			'@name'|'@href'|'@title'|'@class' )
				_meta="${_meta:-}${_meta:+${_n}}${_line}"
				;;
			# Other elements
			[a-z]* )
				if test '*' = "${_selector}"
				then
					_element=1
					test -z "${_meta}" || echo "${_meta}
	"
					echo "${_line}"
				else
					# Iterates over selectors to find a match
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
			# An element separator
			'' )
				test -z "${_element:-}" || echo "${_line}"
				_element=
				;;
		esac
	done
}

# Declares tokens used for parsing
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

# Draws an element list back as a Markdown document formatted for tty
doc_parse_draw ()
{
	doc_parse_tokens

	# A list of elements
	context 'list'
		ifmatch "${_blank}" enter 'element_end'
		ifmatch "@${_anychar}*	" enter 'meta'
		ifmatch "${_anychar}*	" enter 'element'
		print
		next
		ifend quit
		enter 'list'

	# An element
	context 'element'
		ifmatch "h1	" enter 'h1'
		ifmatch "h2	" enter 'h2'
		ifmatch "@title	" enter 'meta'
		ifmatch "code	" enter 'code'
		replace "${_anychar}*	" ''
		print
		next
		enter 'list'

	# Draw H1 as set-atx style
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

	# Draw H2 as set-atx style
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

	# Draws code blocks
	context 'code'
		replace "code	" ''
		enter 'codepad'

	# Pads code blocks to align up terminal colors
	context 'codepad'
		replace '	' '    '
		ifnotmatchall '.\{72\}' enter 'codepadreplace'
		enter 'codepaint'
	context 'codepadreplace'
		replace '$' ' '
		enter 'codepad'

	# Paints a code line
	context 'codepaint'
		replace ".*" "${_dim}${_rev}    ${_reset}${_rev}&${_reset}"
		print
		next
		enter 'list'

	# Ignores invisible elements
	context 'meta'
		next
		ifmatch "${_blank}" enter 'meta'
		enter 'list'

	# The end of an element
	context 'element_end'
		print
		next
		enter 'list'
}

# Parses Markdown input to an element list using the parsed DSL
doc_parse_elements ()
{
	doc_parse_tokens

	# Overall format for ``` and ~~~ fences
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

	# Overall format for atx headings
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

	# Different list of blocks that can appear
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

	# Unspecified text
	context 'text'
		blocks
		ifmatch "${_anychar}" enter 'paragraph'
		ifend quit
		enter 'text'

	# A link reference
	context 'ref'
		remove "${_link_open}"
		detach '@name' "${_link_val}"
		remove "${_link_close}"
		detach '@href' "${_link_until_open}"
		ifmatch "${_title}" enter 'reftitle'
		append
		enter 'text'

	# The title of a link reference
	context 'reftitle'
		remove "${_title_open}"
		detach '@title' "${_title_val}"
		remove "${_title_end}"
		append
		enter 'text'

	# A blank line
	context 'blank'
		delete
		enter 'text'

	# A paragraph
	context 'paragraph'
		line 'text'
		ifmatch "${_blank}" enter 'paragraph'
		blocks
		enter 'paragraph'

	# Indented code
	context 'indent'
		grind 'code' "${_indent}"
		ifmatch "${_blank}" enter 'indent'
		ifmatch "${_indent}" enter 'indent'
		prepend
		blocks
		enter 'text'

	# Tabbed code
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
