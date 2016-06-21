---

[~]:copy:doc/

---

[~]:show
	TEST_SHELLS='busybox sh,zsh,bash'
	IFS=','
	for TARGET in $TEST_SHELLS
	do
		IFS=' '
		posit_shell="eval" $TARGET workshop posit run doc/testing.md
		IFS=','
		for shi in $TEST_SHELLS
		do
			IFS=' '
			posit_shell="$shi" $TARGET workshop posit run doc/testing.md
			IFS=','
		done
	done | workshop untap compare
