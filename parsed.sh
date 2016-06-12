#!/usr/bin/env workshop

# parsed, the sed DSL
#
# Executes a function with parsed DSL language and outputs a sed script
# compatible with most sed versions.
#
parsed ()
{
	# Logs the buffer (for testing purpouses)
	debug ()   ( printf %s\\n '	l' )
	# Defines a sed label
	context () ( printf %s\\n ":_${1}" )
	# Deletes the current line
	delete ()  ( printf %s\\n '	d' )
	# Jumps to a sed label (enters a context)
	enter ()   ( printf %s\\n "	b _${1}" )
	# Gets the pattern from the hold buffer
	get ()     ( printf %s\\n '	g' )
	# Holds the buffer
	hold ()    ( printf %s\\n '	h' )
	# Appends to the hold buffer
	keep ()    ( printf %s\\n '	H' )
	# Marks the output element
	mark ()    ( printf %s\\n "	s/^/${1}	/" )
	# Moves to the next line
	next ()    ( printf %s\\n '	n' )
	# Prints the current line
	print ()   ( printf %s\\n '	p' )
	# Quits parsing
	quit ()    ( printf %s\\n '	q' )
	# Removes a pattern from the start of the line
	remove ()  ( replace "^${1}" '' )
	# Replaces a pattern
	replace () ( printf %s\\n "	s/${1}/${2:-}/" )
	# Swaps the buffer with the hold buffer
	swap ()    ( printf %s\\n '	x' )

	# Marks an element and appends a line
	line ()
	{
		mark "${1}"
		move
	}

	# Marks a subpattern as element, appends a line
	grind ()
	{
		replace "^${2}" ''
		mark "${1}"
		move
	}

	# Prepend text to the line
	prepend ()
	{
		cat <<-SEDN
		i \\
		${*:-}\\

		SEDN
	}

	# Append text to the line
	append ()
	{
		cat <<-SEDN
		a \\
		${*:-}\\

		SEDN
	}

	# Removes a subpattern as an element, puts rest in the buffer
	detach ()
	{
		hold
		get
		replace "\(${2}\).*$" "${1}	\\1"
		print
		get
		replace "^${2}" ''
	}

	# Prints a line and gets a new one
	move ()
	{
		print
		next
	}

	# Performs action if end of script
	ifend ()
	{
		printf %s\\n "$	{"
		"${1}" "${2:-}"
		printf %s\\n "	}"
		echo
	}

	# Performs action if pattern is matched
	ifmatch ()
	{
		printf %s\\n "/^${1}/	{"
		"${2}" "${3:-}"
		printf %s\\n "	}"
		echo
	}

	# Perform action if pattern is not matched
	ifnotmatchall ()
	{
		printf %s\\n "/${1}/!	{"
		"${2}" "${3:-}"
		printf %s\\n "	}"
		printf %s\\n
	}

	# Replace all occurrences of something
	replaceall ()
	{
		cat <<-SEDN
		:_replaceall_${1}
			s/[^${2}]/${2}/
			t _replaceall_${1}
			b _replaceall_${1}_end

		:_replaceall_${1}_end
		SEDN
	}

	# Builds the parser, quits at the end
	_parser="$(${1:-:};quit)"

	# Outputs it
	sed -n "${_parser}"
}

