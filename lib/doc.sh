#!/usr/bin/env workshop

require 'dispatch' 'parsed'

# doc Markdown reader
#
# Doc can partially parse and draw Markdown documents.
#
doc ()
{
	dispatch 'doc' "${@:-}"
}

# Displays a Markdown document friendly to terminals
doc_command_show ()
{
	doc_command_elements "${@:-}" | parsed doc_parse_draw
}

# Outputs a list of elements from a Markdown document
doc_command_elements ()
{
	_file="${1:-}"
	shift

	( cat "${_file}"; echo ) |
		parsed doc_parse_elements | doc_filter "${@:-}"
}

# Filters out elements by a selector
doc_filter ()
{
	_selector="${1:-*}"
	_meta=''
	_n="
"

	# Read the document line by line
	while IFS='' read -r _line
	do
		case "${_line%%	*}" in
			# Line is a meta element
			'@name'|'@href'|'@title'|'@class' )
				_meta="${_meta:-}${_meta:+${_n}}${_line}"
				;;

			# Line is a regular element
			[a-z]* )
				if test '*' = "${_selector}"
				then
					_element=1 # Inside an element
					printf %s\\n "${_line}"
				else
					# Check all selectors in the list
					_ifs="${IFS}"
					IFS=','
					_current="${_line%%	*}" # Remove trailing spaces
					for _sel in ${_selector}
					do
						if test "${_sel}" = "${_current}"
						then
							_element=1 # Inside an element
							printf %s\\n "${_line}"
						fi
					done
					IFS="${_ifs}"
				fi
				_meta=
				;;

			# Line is empty, element ended
			'' )
						test -z "${_meta}" || echo "${_meta}
	"
				test -z "${_element:-}" || printf %s\\n "${_line}"
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
	_bold="$(tput 'bold' 2>/dev/null || :)"
	_rev="$(tput 'rev' 2>/dev/null || :)"
	_dim="$(tput 'dim' 2>/dev/null || :)"
	_reset="$(tput 'sgr0' 2>/dev/null || :)" # Reset last to avoid debug color bleed
}

# Parses a list of elements into a terminal friendly Markdown output
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

	# Inside an element
	context 'element'
		ifmatch "h1	" enter 'h1'
		ifmatch "h2	" enter 'h2'
		ifmatch "@title	" enter 'meta'
		ifmatch "code	" enter 'code'
		replace "${_anychar}*	" ''
		print
		next
		enter 'list'

	# Draw h1 as set-ext style
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

	# Draw h2 as set-ext style
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

	# Inside a code block
	context 'code'
		replace "code	" ''
		enter 'codepad'

	# Pads a code block to 72 chars to highlight it evenly
	context 'codepad'
		replace '	' '    '
		ifnotmatchall '.\{72\}' enter 'codepadreplace'
		enter 'codepaint'
	context 'codepadreplace'
		replace '$' ' '
		enter 'codepad'

	# Paints a code line, highlighting it
	context 'codepaint'
		replace ".*" "${_dim}${_rev}    ${_reset}${_rev}&${_reset}"
		print
		next
		enter 'list'

	# Hide out invisible meta attributes
	context 'meta'
		next
		ifmatch "${_blank}" enter 'meta'
		enter 'list'

	# Back to list when element ends
	context 'element_end'
		print
		next
		enter 'list'
}

# Parses a Markdown document into a list of elements
doc_parse_elements ()
{
	flash "Parsing..."
	doc_parse_tokens

	# Overall format of a code fence
	fence ()
	{
		# Fence context with its nane
		context "${1}"
			remove "${2}"
			ifmatch "${_anychar}"  enter "${1}_attr"
			next
			ifmatch "${2}"  enter "${1}_out"
			ifmatch "${_anychar}" enter "${1}_inside"
			ifmatch "${_blank}" enter "${1}_inside"
			enter "${1}"

		# The fence attribute (sh in ```sh)
		context "${1}_attr"
			append
			line '@class'
			ifmatch "${2}"  enter "${1}_out"
			ifmatch "${_anychar}" enter "${1}_inside"
			ifmatch "${_blank}" enter "${1}_inside"
			enter "${1}"

		# Code inside a fence
		context "${1}_inside"
			line "code" "${_anychar}"
			ifmatch "${2}"  enter "${1}_out"
			ifmatch "${_anychar}" enter "${1}_inside"
			ifmatch "${_blank}" enter "${1}_inside"
			enter "${1}"

		# End of a fence
		context "${1}_out"
			append
			delete
			enter 'text'
	}

	# Overall format of an atx heading
	heading ()
	{
		# Heading context with its name
		context "${1}"
			remove "${2}"
			hold
			next
			ifmatch "${_blank}" enter "${1}blank"
			get
			append
			line "${1}"
			enter 'text'

		# Blank line after the heading
		context "${1}blank"
			get
			append
			line "${1}"
			enter 'text'
	}

	# A list of possible blocks that might appear
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

	# Unspecified Markdown text
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

	# A link reference title
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

	# Code indented with spaces
	context 'indent'
		grind 'code' "${_indent}"
		ifmatch "${_blank}" enter 'indent'
		ifmatch "${_indent}" enter 'indent'
		prepend
		blocks
		enter 'text'

	# Code indented with a tab
	context 'tabbed'
		grind 'code' "${_tabbed}"
		ifmatch "${_blank}" enter 'tabbed'
		ifmatch "${_tabbed}" enter 'tabbed'
		prepend
		blocks
		enter 'text'

	# Dumps headings and fence rules
	heading "h1" "${_h1}"
	heading "h2" "${_h2}"
	heading "h3" "${_h3}"
	heading "h4" "${_h4}"
	heading "h5" "${_h5}"
	heading "h6" "${_h6}"
	fence "ticked" "${_ticked}"
	fence "tilded" "${_tilded}"

	flash
}
