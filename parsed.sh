#!/usr/bin/env workshop

parsed ()
{
	context ()
	{
		printf %s\\n ":_${1}"
	}

	print ()
	{
		printf %s\\n '	p'
	}

	mark ()
	{
		printf %s\\n "	s/^/${1}	/"
	}

	delete ()
	{
		printf %s\\n '	d'
	}

	next ()
	{
		printf %s\\n '	n'
	}

	quit ()
	{
		printf %s\\n '	q'
	}

	debug ()
	{
		printf %s\\n '	l'
	}

	line ()
	{
		mark "${1}"
		move
	}

	remove ()
	{
		replace "^${1}" ''
	}

	replace ()
	{
		printf %s\\n "	s/${1}/${2:-}/"
	}

	grind ()
	{
		replace "^${2}" ''
		mark "${1}"
		move
	}

	prepend ()
	{
		cat <<-SEDN
		i \\
		${*:-}\\

		SEDN
	}

	append ()
	{
		cat <<-SEDN
		a \\
		${*:-}\\

		SEDN
	}

	hold ()
	{
		printf %s\\n '	h'
	}

	keep ()
	{
		printf %s\\n '	H'
	}

	get ()
	{
		printf %s\\n '	g'
	}

	detach ()
	{
		hold
		get
		replace "\(${2}\).*$" "${1}	\\1"
		print
		get
		replace "^${2}" ''
	}

	move ()
	{
		print
		next
	}

	ifend ()
	{
		printf %s\\n "$	{"
		"${1}" "${2:-}"
		printf %s\\n "	}"
		echo
	}

	ifmatch ()
	{
		printf %s\\n "/^${1}/	{"
		"${2}" "${3:-}"
		printf %s\\n "	}"
		echo
	}

	ifnotmatchall ()
	{
		printf %s\\n "/${1}/!	{"
		"${2}" "${3:-}"
		printf %s\\n "	}"
		printf %s\\n
	}

	swap ()
	{
		printf %s\\n '	x'
	}

	enter ()
	{
		printf %s\\n "	b _${1}"
	}

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

	_parser="$(${1:-:};quit)"

	#echo "${_parser}" 1>&2
	sed -n "${_parser}"
}

