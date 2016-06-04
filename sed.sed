:_stream
$ { b endparsing }
/^$/ { n; b _stream }
/^0	\(.*\)$/ { b _document }
b endstream

:_document
s/^[0-9][0-9]*	//
s/^\([a-f0-9]*\)	\(.*\)/doc_path () ( echo \'\2\' | "${1:-cat}" )\
/p
$ { b endoutput }
n
/^[0-9][0-9]*	\(	\|    \)\(.*\)$/   { b _code_indented_open }
/^[0-9][0-9]*	\(~~~\|```\)\([a-zA-Z0-9]*\)\(.*\)$/    { h ; b _code_fenced }
/^\([0-9][0-9]*\)	\(\[~\]\:\)\([a-zA-Z0-9:]*\)\s*(*\([^)]*\)\s*)*\s*$/     { b _meta_annotation_in }
# Standard line based output
h
s/^\([0-9][0-9]*\)	\(.*\)/doc_list=\"${doc_list:-} text_\1\"\
\
doc_text_\1 ()\
{\
/p
i \
\	cat <<'O_doc_' | "${1:-cat}"
x
$ { b endoutput }
b _identify_line

:_print_text_line
s/^[0-9][0-9]*	//

p
$ { b endoutput }
N
s/^.*//

:_identify_line
/^[0-9][0-9]*	\(	\|    \)\(.*\)$/   { b _code_indented_open }
/^[0-9][0-9]*	\(~~~\|```\)\([a-zA-Z0-9]*\)\(.*\)$/    { h ; b _code_fenced }
/^\([0-9][0-9]*\)	\(\[~\]\:\)\([a-zA-Z0-9:]*\)\s*(*\([^)]*\)\s*)*\s*$/     { b _meta_annotation }
/^[0-9][0-9]*	\(.*\)/     { b _print_text_line }
b endstream

:_meta_annotation
i \
O_doc_
i \
}
i \

:_meta_annotation_in
h
x
h
s/^\([0-9][0-9]*\)	\(\[~\]\:\)\([a-zA-Z0-9:]*\)\s*(*\([^)]*\)\s*)*\s*$/\3/
s/[^a-zA-Z0-9]/_/g
x
s/^\([0-9][0-9]*\)	\(\[~\]\:\)\([a-zA-Z0-9:]*\)\s*(*\([^)]*\)\s*)*\s*$/doc_\3_\1_attr () ( echo '\4' | "${1:-cat}"  )\
\
doc_\3_\1 () \
{/

/doc_\([a-zA-Z0-9_]*\):/ {
s/_[0-9][0-9]*_attr () (/_attr () (/
s/_[0-9][0-9]* () {/ () {/
}
:_meta_annotation_loop
s/doc_\([a-zA-Z0-9_]*\):/doc_\1_/
t _meta_annotation_loop

s/^doc_\([a-zA-Z0-9_]*\)_attr/doc_list="${doc_list:-} \1"\
\
doc_\1_attr/
p
$ { b endmeta }
b _annotated_block

:_annotated_block
$ { b endmeta }
s/^[0-9][0-9]*	//

$ { b endmeta }
n
/^[0-9][0-9]*	$/   { b _annotated_block }
/^[0-9][0-9]*	\(	\|    \)\(.*\)$/   { b _annotated_code_open }
/^\([0-9][0-9]*\)	\(\[~\]\:\)\([a-zA-Z0-9:]*\)\s*(*\([^)]*\)\s*)*\s*$/     {
i \
\	cat <<'O_doc_' | "${1:-cat}"
b _meta_annotation
}
/^[0-9][0-9]*	\(~~~\|```\)\([a-zA-Z0-9]*\)\(.*\)$/    {
h
b _annotated_fence_open
}
h
s/^\([0-9][0-9]*\)	\(.*\)$/	echo text_\1 | "${1:-cat}" 1>\&2/p
g
i \
}
i \

# Standard line based output
h
s/^\([0-9][0-9]*\)	\(.*\)/doc_list=\"${doc_list:-} text_\1\"\
\
doc_text_\1 ()\
{\
/p
i \
\	cat <<'O_doc_' | "${1:-cat}"
x
b _print_text_line

:_annotated_fence_open
s/^\([0-9][0-9]*\)	\(~~~\|```\)\([a-zA-Z0-9]*\)\(.*\)$/	echo fence_\1 | "${1:-cat}"  1>\&2\
}\
\
doc_list="${doc_list:-} fence_\1"\
\
doc_fence_\1_attr () ( echo '\2\3' | "${1:-cat}" )\
\
doc_fence_\1 () \
{/
p
$ { b endoutput }
n
/^[0-9][0-9]*	\(~~~\|```\)\([a-zA-Z0-9]*\)\(.*\)$/ {
i \
\	cat <<'O_doc_' | "${1:-cat}"
b _code_fenced_close
}
/^[0-9][0-9]*	[a-zA-Z0-9@]*\(\$\|>\|%\) */! {
i \
\	cat <<'O_doc_' | "${1:-cat}"
b _code_fenced_in
}
i \
\	cat <<'I_doc_' | "${2:-cat}"
a \
I_doc_
a \
\	cat <<'O_doc_' | "${1:-cat}"
s/^[0-9][0-9]*	//

p
$ { b endoutput }
n
b _code_fenced_in

:_annotated_code_open
h
s/^\([0-9][0-9]*\)	\(.*\)/	echo indent_\1 | "${1:-cat}" 1>\&2\
}\
\
doc_list="${doc_list:-} indent_\1"\
\
doc_indent_\1 ()\
{/
p
x
/^[0-9][0-9]*		[a-zA-Z0-9@]*\(\$\|>\|%\) */! {
i \
\	cat <<'O_doc_' | "${1:-cat}"
b _code_indented
}
i \
\	cat <<'I_doc_' | "${2:-cat}"
a \
I_doc_
a \
\	cat <<'O_doc_' | "${1:-cat}"
s/^[0-9][0-9]*		*\(	\|\s\)*//p
$ { b endoutput }
n
b _code_indented

:_code_indented_open
i \
O_doc_
i \
}
i \

h
s/^\([0-9][0-9]*\)	\(.*\)/doc_list="${doc_list:-} indent_\1"\
\
doc_indent_\1 () \
{/
p
x
i \
\	cat <<'O_doc_' | "${1:-cat}"
b _code_indented

:_code_indented
/^[0-9][0-9]*		[a-zA-Z0-9@]*\(\$\|>\|%\) */ {
i \
O_doc_
i \
\	cat <<'I_doc_' | "${2:-cat}"
a \
I_doc_
a \
\	cat <<'O_doc_' | "${1:-cat}"
s/^[0-9][0-9]*		*\(	\|\s\)*//

p
$ { b endoutput }
n
b _code_indented
}
s/^[0-9][0-9]*		*\(	\|\s\)*//
/^$/! p
$ { b endoutput }

N

// {
s/^//
/^[0-9][0-9]*	\(	\|    \)\(.*\)$/ {
i \

b _code_indented
}
/^[0-9][0-9]*	$/ {
i \

b _code_indented
}
}
s/^\(.*\)\(.*\)$/\2/
/^[0-9][0-9]*	\(	\|    \)\(.*\)$/ { b _code_indented }
/^[0-9][0-9]*	$/ { b _code_indented }
/^\([0-9][0-9]*\)	\(\[~\]\:\)\([a-zA-Z0-9:]*\)\s*(*\([^)]*\)\s*)*\s*$/   { b _meta_annotation }
/^[0-9][0-9]*	\(.*\)/   {
i \
O_doc_
b _code_indented_close
}
b endstream


:_code_indented_close
/^\([0-9][0-9]*\)	\(\[~\]\:\)\([a-zA-Z0-9:]*\)\s*(*\([^)]*\)\s*)*\s*$/    { b _meta_annotation }
i \
}
i \

# Standard line based output
h
s/^\([0-9][0-9]*\)	\(.*\)/doc_list=\"${doc_list:-} text_\1\"\
\
doc_text_\1 ()\
{\
/p
i \
\	cat <<'O_doc_' | "${1:-cat}"
x
b _identify_line

:_code_fenced
i \
O_doc_
i \
}
i \

s/^\([0-9][0-9]*\)	\(.*\)/doc_list="${doc_list:-} fence_\1"\
\
doc_fence_\1_attr () ( echo '\2' | "${1:-cat}" )\
\
doc_fence_\1 () \
{/p
$ { b endoutput }
n
/^[0-9][0-9]*	\(~~~\|```\)\([a-zA-Z0-9]*\)\(.*\)$/ {
i \
\	cat <<'O_doc_' | "${1:-cat}"
b _code_fenced_close
}
i \
\	cat <<'O_doc_' | "${1:-cat}"
b _code_fenced_in

:_code_fenced_in
/^[0-9][0-9]*	[a-zA-Z0-9@]*\(\$\|>\|%\) */ {
i \
O_doc_
i \
\	cat <<'I_doc_' | "${2:-cat}"
a \
I_doc_
a \
\	cat <<'O_doc_' | "${1:-cat}"
s/^[0-9][0-9]*	//

p
$ { b endoutput }
n

/^[0-9][0-9]*	\(~~~\|```\)\([a-zA-Z0-9]*\)\(.*\)$/ {
        G
# Closes fences

        /^[0-9][0-9]*	~~~\
[0-9][0-9]*	~~~/ { b _code_fenced_close }

        /^[0-9][0-9]*	```\
[0-9][0-9]*	```/  { b _code_fenced_close }

        s/^\([0-9][0-9]*	\)\(~~~\|```\).*/\1\2/
b _code_fenced_in
}
b _code_fenced_in
}
/^[0-9][0-9]*	\(~~~\|```\)\([a-zA-Z0-9]*\)\(.*\)$/ {
        G
# Closes fences

        /^[0-9][0-9]*	~~~\
[0-9][0-9]*	~~~/ { b _code_fenced_close }

        /^[0-9][0-9]*	```\
[0-9][0-9]*	```/  { b _code_fenced_close }

        s/^\([0-9][0-9]*	\)\(~~~\|```\).*/\1\2/
b _code_fenced_in
}
s/^[0-9][0-9]*	//
p
$ { b endoutput }
n
    b _code_fenced_in

:_code_fenced_close
        	s/^\([0-9][0-9]*	\)\(~~~\|```\).*/\1\2/
        	s/^[0-9][0-9]*	//
        	s/^\(.*\)$//
i \
O_doc_
i \
}
i \

p
$ { b endstream }
n
# Standard line based output
h
s/^\([0-9][0-9]*\)	\(.*\)/doc_list=\"${doc_list:-} text_\1\"\
\
doc_text_\1 ()\
{\
/p
i \
\	cat <<'O_doc_' | "${1:-cat}"
x
b _identify_line

:endoutput
a \
O_doc_
b endnormal
:endmeta
a \
:
:endnormal
a \
}
:endstream
a \
doc_list () ( echo "$doc_list" )
# Dispatch parameters
a [ -z \"${1:-}\" ] && ${2:-:} \"$doc_list\" 1>&2 || doc_${@:-}
:endparsing