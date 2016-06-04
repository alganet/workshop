doc_tab=$(printf '\t')
doc_parser=""
doc_prefix="doc_"
doc_env="/usr/bin/env sh"

doc () ( doc_command_"${@:-}" )

# Gets the source for a markdown file
doc_command_source () {
	doc_parse "${@:-}"
}


# Builds the parser
doc_command_build () {
	doc_parser_build "${doc_prefix}"
}

doc_command_list ()
{
	doc_load "${1:-}"

	${doc_prefix}list |
		sed 's/\([a-zA-Z0-9]*\)_/\1:/g' |
		sed -n "/^\s${2:-.*}/p"
}

doc_command_inspect ()
{
	doc_command_get "${@:-}"
}

doc_command_get ()
{
	doc_load "${1:-}"
	doc_block_id="${2:-}"
	shift 2
	doc_command="$(printf "${doc_block_id}" | tr ':' '_')"
	doc_args="${@:-}"
	set --
	case "${doc_block_id}" in
		*:attr )
			${doc_prefix}${doc_command} "${doc_args:-}"
			;;
		text:*|indent:*|fence:* )
			${doc_prefix}${doc_command} "${doc_args:-}"
			;;
		* )
			doc_redir="$(${doc_prefix}${doc_command} "${doc_args:-}" 2>&1)"
			[ -z "$doc_redir" ] || "${doc_prefix}${doc_redir}" "${doc_args:-}"
			;;
	esac
}

doc_parse () {
	doc_sed_line="sed -n"
	doc_sed="$(doc_parser_build ${doc_prefix})"
	printf %s "${doc_sed}" > sed.sed
	if [ -f "${doc_parser}" ]
	then
		doc_sed_line="sed -n -f"
		doc_sed="${doc_parser}"
	fi

	if [ -f "${1:-}" ]
	then
		doc_prepare "${PWD}/${1}" | ${doc_sed_line} "${doc_sed}"
	fi
}

# Prepares the parser to run
doc_prepare () {
	doc_filename="${1}"
	echo
	echo "0${doc_tab}${doc_tab}${doc_filename}"
	sed '=' "$doc_filename" | sed "N;s/\n/${doc_tab}/"
}

# Does something in the parsers environment
doc_load () {
	doc_file="${1:-}"
	shift
	set -- '' :
	eval "$(doc_parse "${doc_file}")"
}

# Builds a sed script that generates code from markdown files
doc_parser_build () {
(
	d_prefix="${1:-${doc_prefix}}"
	d_hash="$(echo ${d_prefix})"
	# A literal tab
    d_tab=$(printf '\t')
    d_digits="[0-9][0-9]*"
    d_alnum="a-zA-Z0-9"
    d_anything="\(.*\)"
    d_fence_tick="\`\`\`"
    d_fence_tilde="~~~"
    # The standard prefix for a document line
    d_line="${d_digits}${d_tab}"
    # The beginning of a document, prefixed
    d_stream_doc="/^0${d_tab}${d_anything}$/"
    #Expression to hold fence delimiters
    d_both_fences="${d_fence_tilde}\|${d_fence_tick}"
    # Any line from a document
    doc_line="/^${d_line}${d_anything}/"
    # An indented block of code on a document
    doc_indent="/^${d_line}\(${d_tab}\|    \)${d_anything}$/"
    # The beginning or ending of a code fence
    doc_fence="/^${d_line}\(${d_both_fences}\)\([${d_alnum}]*\)${d_anything}$/"
    # An invisible link used to reference code blocks
    doc_meta="/^\(${d_digits}\)${d_tab}\(\[~\]\:\)\([${d_alnum}:]*\)\s*(*\([^)]*\)\s*)*\s*$/"
	# Sed expression used to remove the standard prefix
	d_remove_number="s/^${d_line}//"
	# An expression that matches an empty prefixed line
	d_empty_line="/^${d_line}$/"
	# Sed expression to close an open fence
	d_close_fence="s/^\(${d_line}\)\(${d_both_fences}\).*/\1\2/"
	# Sed expression to add shell code that expands parameters
	d_param_dispatch="$(cat <<-SED
		# Dispatch parameters
		a \\
		[ -z \"\${1:-}\" ] && \${2:-:} \"\$${d_prefix}list\" 1>&2 || ${d_prefix}\${@:-}
		SED
	)"
	# Shell expression to start an output block
	d_block_output="\	cat <<'O_${d_hash}' | \"\${1:-cat}\""
	# Shell expression to start an input block
	d_block_input="\	cat <<'I_${d_hash}' | \"\${2:-cat}\""
	# Common markdown fence closing sed expression
	d_prompt_spec="[${d_alnum}@]*\(\\\$\|>\|%\) *"
	d_fence_common="$(cat <<-SED
	        G
		# Closes fences

	        /^${d_line}${d_fence_tilde}\
			${d_line}${d_fence_tilde}/ {
				b _code_fenced_close
			}

	        /^${d_line}${d_fence_tick}\
			${d_line}${d_fence_tick}/  {
				b _code_fenced_close
			}

	        ${d_close_fence}
		SED
	)"
	doc_list="s/^\(${d_digits}\)${d_tab}${d_anything}/${d_prefix}list="
	# Expression to mark the starting line of a text with a function
	d_text_mark="$(cat <<-SED
		# Standard line based output
		h
		${doc_list}\"\${${d_prefix}list:-} text_\1\"\
		\
		${d_prefix}text_\1 ()\
		{\
		/p
		i \\
		${d_block_output}
		x
		SED
	)"
	# Main sed script built with templates above
    cat <<-SED
	:_stream
		$ {
			b endparsing
		}
		/^$/ {
			n
		 	b _stream
	 	}
		${d_stream_doc} {
			b _document
		}
		b endstream

	:_document
		${d_remove_number}
		s/^\([a-f0-9]*\)${d_tab}${d_anything}/${d_prefix}path () ( echo \'\2\' | "\${1:-cat}" )\
		/p
		$ {
			b endoutput
		}
		n
		${doc_indent}   {
			b _code_indented_open
		}
		${doc_fence}    {
			h
			b _code_fenced
		}
		${doc_meta}     {
			b _meta_annotation_in
		}
		${d_text_mark}
		$ {
			b endoutput
		}
		b _identify_line

	:_print_text_line
		${d_remove_number}

		p
		$ {
			b endoutput
		}
		N
		s/^.*\
		//

	:_identify_line
		${doc_indent}   {
			b _code_indented_open
		}
		${doc_fence}    {
			h
			b _code_fenced
		}
		${doc_meta}     {
			b _meta_annotation
		}
		${doc_line}     {
			b _print_text_line
		}
		b endstream

	:_meta_annotation
		i \\
		O_${d_hash}
		i \\
		}
		i \\

	:_meta_annotation_in
		h
		x
		h
		s${doc_meta}\3/
		s/[^${d_alnum}]/_/g
		x
		s${doc_meta}${d_prefix}\3_\1_attr () ( echo '\4' | "\${1:-cat}"  )\
		\
		${d_prefix}\3_\1 () \
		{/

		/${d_prefix}\([${d_alnum}_]*\):/ {
			s/_${d_digits}_attr () (/_attr () (/
			s/_${d_digits} () \
			{/ () \
			{/
		}
		:_meta_annotation_loop
			s/${d_prefix}\([${d_alnum}_]*\):/${d_prefix}\1_/
			t _meta_annotation_loop

		s/^${d_prefix}\([${d_alnum}_]*\)_attr/${d_prefix}list="\${${d_prefix}list:-} \1"\
		\
		${d_prefix}\1_attr/
		p
		$ {
			b endmeta
		}
		b _annotated_block

	:_annotated_block
		$ {
			b endmeta
		}
		${d_remove_number}

		$ {
			b endmeta
		}
		n
		${d_empty_line}   {
			b _annotated_block
		}
		${doc_indent}   {
			b _annotated_code_open
		}
		${doc_meta}     {
			i \\
			${d_block_output}
			b _meta_annotation
		}
		${doc_fence}    {
			h
			b _annotated_fence_open
		}
		h
		s/^\(${d_digits}\)${d_tab}${d_anything}$/	echo text_\1 | "\${1:-cat}" 1>\&2/p
		g
		i \\
		}
		i \\

		${d_text_mark}
		b _print_text_line

	:_annotated_fence_open
		s/^\(${d_digits}\)${d_tab}\(${d_both_fences}\)\([${d_alnum}]*\)${d_anything}$/	echo fence_\1 | "\${1:-cat}"  1>\&2\
		}\
		\
		${d_prefix}list="\${${d_prefix}list:-} fence_\1"\
		\
		${d_prefix}fence_\1_attr () ( echo '\2\3' | "\${1:-cat}" )\
		\
		${d_prefix}fence_\1 () \
		{/
		p
		$ {
			b endoutput
		}
		n
		${doc_fence} {
			i \\
			${d_block_output}
			b _code_fenced_close
		}
		/^${d_line}${d_prompt_spec}/! {
			i \\
			${d_block_output}
			b _code_fenced_in
		}
		i \\
		${d_block_input}
		a \\
		I_${d_hash}
		a \\
		${d_block_output}
		${d_remove_number}

		p
		$ {
			b endoutput
		}
		n
		b _code_fenced_in

	:_annotated_code_open
		h
		s/^\(${d_digits}\)${d_tab}${d_anything}/	echo indent_\1 | "\${1:-cat}" 1>\&2\
		}\
		\
		${d_prefix}list="\${${d_prefix}list:-} indent_\1"\
		\
		${d_prefix}indent_\1 ()\
		{/
		p
		x
		/^${d_line}${d_tab}${d_prompt_spec}/! {
			i \\
			${d_block_output}
			b _code_indented
		}
		i \\
		${d_block_input}
		a \\
		I_${d_hash}
		a \\
		${d_block_output}
		s/^${d_line}${d_tab}*\(${d_tab}\|\s\)*//p
		$ {
			b endoutput
		}
		n
		b _code_indented

	:_code_indented_open
		i \\
		O_${d_hash}
		i \\
		}
		i \\

		h
		${doc_list}"\${${d_prefix}list:-} indent_\1"\
		\
		${d_prefix}indent_\1 () \
		{/
		p
		x
		i \\
		${d_block_output}
		b _code_indented

	:_code_indented
		/^${d_line}${d_tab}${d_prompt_spec}/ {
			i \\
			O_${d_hash}
			i \\
			${d_block_input}
			a \\
			I_${d_hash}
			a \\
			${d_block_output}
			s/^${d_line}${d_tab}*\(${d_tab}\|\s\)*//

			p
			$ {
				b endoutput
			}
			n
			b _code_indented
		}
		s/^${d_line}${d_tab}*\(${d_tab}\|\s\)*//
		/^$/! p
		$ {
			b endoutput
		}

		N

		/\
		/ {
			s/^\
			//
			${doc_indent} {
				i \\

				b _code_indented
			}
			${d_empty_line} {
				i \\

				b _code_indented
			}
		}
		s/^${d_anything}\
		${d_anything}$/\2/
		${doc_indent} {
			b _code_indented
		}
		${d_empty_line} {
			b _code_indented
		}
		${doc_meta}   {
			b _meta_annotation
		}
		${doc_line}   {
			i \\
			O_${d_hash}
			b _code_indented_close
		}
		b endstream


	:_code_indented_close
		${doc_meta}    {
			b _meta_annotation
		}
		i \\
		}
		i \\

		${d_text_mark}
		b _identify_line

	:_code_fenced
		i \\
		O_${d_hash}
		i \\
		}
		i \\

		${doc_list}"\${${d_prefix}list:-} fence_\1"\
		\
		${d_prefix}fence_\1_attr () ( echo '\2' | "\${1:-cat}" )\
		\
		${d_prefix}fence_\1 () \
		{/p
		$ {
			b endoutput
		}
		n
		${doc_fence} {
			i \\
			${d_block_output}
			b _code_fenced_close
		}
		i \\
		${d_block_output}
		b _code_fenced_in

	:_code_fenced_in
		/^${d_line}${d_prompt_spec}/ {
			i \\
			O_${d_hash}
			i \\
			${d_block_input}
			a \\
			I_${d_hash}
			a \\
			${d_block_output}
			${d_remove_number}

			p
			$ {
				b endoutput
			}
			n

			${doc_fence} {
				${d_fence_common}
				b _code_fenced_in
			}
			b _code_fenced_in
		}
		${doc_fence} {
			${d_fence_common}
			b _code_fenced_in
		}
		${d_remove_number}
		p
		$ {
			b endoutput
		}
		n
	    b _code_fenced_in

	:_code_fenced_close
        	${d_close_fence}
        	${d_remove_number}
        	s/^${d_anything}$//
		i \\
		O_${d_hash}
		i \\
		}
		i \\

		p
		$ {
			b endstream
		}
		n
		${d_text_mark}
		b _identify_line

	:endoutput
		a \\
		O_${d_hash}
		b endnormal
	:endmeta
		a \\
		:
	:endnormal
		a \\
		}
	:endstream
		a \\
		${d_prefix}list () ( echo "\$${d_prefix}list" )
		${d_param_dispatch}
	:endparsing

	SED
    )
}

