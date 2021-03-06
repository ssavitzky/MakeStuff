
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
#	TODO: It's also an open question whether it should be allowed to clobber a
#	commit made on a different day.
#

.PHONY: save Save

last_commit_subject = $(wordlist 1,3,$(subst -, ,$(shell git log -n1 --format=%f)))
save_may_amend = $(findstring Saved on $(shell hostname),$(last_commit_subject))
ifdef SAVE_MAY_AMEND_PUSH
save_may_amend += $(findstring Push from $(shell hostname),$(last_commit_subject))
endif
save:
	@if [ -z "`git status --porcelain`" ]; then echo Up to date -- not saving.;	\
	    echo See whether push is required; git push;				\
	elif [ ! -z "$(save_may_amend)" ]; then						\
	    echo Save will amend existing commit $(last_commit_subject);		\
	    git commit -a --amend -m "Saved on $(COMMIT_MSG)";				\
	    git push --force-with-lease || (echo === pull --rebase needed; false)	\
	else										\
	    echo Saving.  Previous commit was not a save, so not forcing;		\
	    git commit -a -m "Saved on $(COMMIT_MSG)";					\
	    git push || (echo === pull --rebase needed; false)				\
	fi

# Save: works like save: only it will also overwrite `Push from` commits.

Save: save_may_amend += $(findstring Push from $(shell hostname),$(last_commit_subject))
Save: save
