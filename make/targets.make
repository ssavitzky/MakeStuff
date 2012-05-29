#!/usr/bin/make  ### targets.make - basic targets for makefiles
#
# This file is meant to be included by Tools/Makefile, and defines a
# generally-useful collection of targets.
#
# Note that targets in this file will not be found by bash autocomplete. 

### git-related targets

.PHONY: push pull

# push:  do the subdirectories first.  Try make before resorting to git
#
push:: 
	for d in $(GIT_DIRS); do 					\
	    if [ -d $$d/.git/refs/remotes/origin ]; then 		\
		(cd $$d; $(MAKE) push || git push | tee /dev/null); 	\
	    fi; 							\
	done

# push"	 This target does a snapshot "commit -a" before pushing.
push::  all
	@if [ -d .git/refs/remotes/origin ]; then		\
	   git commit -a -m "push from `hostname` `date`" &&	\
	   git push origin | tee /dev/null;			\
	fi

pull:: 
	for d in $(GIT_DIRS); do (cd $$d; 			\
	    ($(MAKE) pull || git pull origin : | tee /dev/null); done
pull::
	@if [ -d .git ]; then git pull origin : | tee /dev/null; fi


### reporting

sloc.log:: 
	sloccount --addlang makefile . > $@

###### end of targets.make ######
