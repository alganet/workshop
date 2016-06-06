#!/usr/bin/env workshop

parsed ()
{
	context ()
	{
		echo ":_${1}"
	}

	print ()
	{
		echo '	p'
	}

	mark ()
	{
		echo "	s/^/${1}	/"
	}

	delete ()
	{
		echo '	d'
	}

	next ()
	{
		echo '	n'
	}

	quit ()
	{
		echo '	q'
	}

	debug ()
	{
		echo '	l'
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
		echo "	s/${1}/${2:-}/"
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
		i \
		${*:-}
		SEDN
	}

	append ()
	{
		cat <<-SEDN
		a \
		${*:-}
		SEDN
	}

	hold ()
	{
		echo '	h'
	}

	keep ()
	{
		echo '	H'
	}

	get ()
	{
		echo '	g'
	}

	detach ()
	{
		hold
		get
		replace "^\(${2}\).*" "${1}	\1"
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
		echo "$	{"
		"${1}" "${2:-}"
		echo "	}"
		echo
	}

	ifmatch ()
	{
		echo "/^${1}/	{"
		"${2}" "${3:-}"
		echo "	}"
		echo
	}

	ifnotmatchall ()
	{
		echo "/${1}/!	{"
		"${2}" "${3:-}"
		echo "	}"
		echo
	}

	swap ()
	{
		echo '	x'
	}

	enter ()
	{
		echo "	b _${1}"
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

