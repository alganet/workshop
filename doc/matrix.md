---

[~]:copy:doc/

---

[~]:show
	TEST_SHELLS='zsh bash'
	for TARGET in $TEST_SHELLS
	do
		for shi in $TEST_SHELLS eval
		do
			posit_shell=$shi $TARGET workshop posit run doc/testing.md
		done
	done | workshop untap compare
