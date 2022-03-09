### MakeStuff plugin to safely amend trivial commits
#
#	Usually included along with .blog.defaults.make; it may be used separately in
#	other cases, mostly in connection with `to.do` logs.  It makes the most sense
#	in repositories	that do not have a `post-update` hook that automatically pulls
#	into a working tree on the server.

# save is used to reduce trivial commits while working on posts and to.do logs
#	It uses --amend and --force-with-lease to keep from having a long sequence of
#	commits that differ in only a line or two.  Errors if something else as been
#	committed since the last save.
#
#	save retains previous subject lines in the commit message; this is done by
#	setting GIT_EDITOR to save-amend-commit
#
# Options:
#   set SAVE_MAY_AMEND_PUSH to allow a save to amend a previous commit that starts with
#	`Push from` ...  You can use `make push` to start a new sequence of saves.  You
#	can use `make Save` to do this rather than setting the variable on the command
#	line.
#
#   set	SAVE_MAY_IGNORE_DATE to allow a save to amend a save commit made on a different
#	day.
#
# See also: https://stackoverflow.com/questions/42857506/\
 #	    how-to-automatically-git-commit-amend-to-append-to-last-commit-message#42857774

.PHONY: save Save

ifdef SAVE_MAY_IGNORE_DATE
save_test = 3
save_tail = $(wordlist 1,1,$(COMMIT_MSG))
else
save_test = 7
save_tail = $(wordlist 1,5,$(COMMIT_MSG))
endif
# save_msg_tail is the last part of the _next_ commit message.
last_commit_subject = $(subst -, ,$(shell git log -n1 --format=%f))
trimmed_commit_subject = $(wordlist 1,$(save_test),$(last_commit_subject))
save_may_amend = $(findstring Saved on $(save_tail),$(trimmed_commit_subject))
ifdef SAVE_MAY_AMEND_PUSH
save_may_amend += $(findstring Push from $(save_tail),$(trimmed_commit_subject))
endif

build_new_commit_message = echo 'Saved on $(COMMIT_MSG)' >> $$1;

Save save:
	@if git status --porcelain; then 					\
	    echo $@: nothing to commit, working tree clean; git push;			\
	elif [ ! -z "$(save_may_amend)" ]; then						\
	    echo $@: amending  $(trimmed_commit_subject) ...;				\
	    GIT_EDITOR=$(TOOLDIR)/blogging/save-amend-commit				\
		NEW_MESSAGE='Saved on $(COMMIT_MSG)' git commit -a --amend;		\
	    git push --force-with-lease || (echo === pull --rebase needed; false)	\
	else										\
	    echo $@: following $(last_commit_subject);					\
	    git commit -a -m "Saved on $(COMMIT_MSG)";					\
	    git push || (echo === pull --rebase needed; false)				\
	fi

# Save: works like save:, but it will also overwrite `Push from` commits.

Save: save_may_amend += $(findstring Push from $(shell hostname),$(trimmed_commit_subject))


