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
#	It's an open question whether to save if the last operation was `make push`
#	... so we make it an option, controled by SAVE_MAY_AMEND_PUSH
#
#	It's also an open question whether it should be allowed to clobber a commit made
#	on a different day.  To allow that, define SAVE_MAY_IGNORE_DATE
#
#	to keep save history, should append each save time to the commit message.
#	See https://stackoverflow.com/questions/42857506/\
#	    how-to-automatically-git-commit-amend-to-append-to-last-commit-message#42857774
#	OLD_MSG=$(git log --format=%B -n1)
#	GIT_EDITOR="echo 'appended line' >> $1" git commit --amend

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

save:
	@if [ -z "`git status --porcelain`" ]; then 					\
	    echo Save: commit not needed; git push;					\
	elif [ ! -z "$(save_may_amend)" ]; then						\
	    echo Save: amending $(trimmed_commit_subject) ...;				\
	    GIT_EDITOR=$(TOOLDIR)/blogging/save-amend-commit				\
		NEW_MESSAGE='Saved on $(COMMIT_MSG)' git commit -a --amend;		\
	    git push --force-with-lease || (echo === pull --rebase needed; false)	\
	else										\
	    echo Save: will not amend $(trimmed_commit_subject) ...;			\
	    git commit -a -m "Saved on $(COMMIT_MSG)";					\
	    git push || (echo === pull --rebase needed; false)				\
	fi

# Save: works like save: only it will also overwrite `Push from` commits.

Save: save_may_amend += $(findstring Push from $(shell hostname),$(trimmed_commit_subject))
Save: save
