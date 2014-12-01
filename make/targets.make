#!/usr/bin/make  ### targets.make - basic targets for makefiles
#
# This file is meant to be included by Tools/Makefile, and defines a
# generally-useful collection of targets.
#
# Note that targets in this file will not be found by bash autocomplete. 


### deployment
.PHONY: push pull pre-deployment deploy-only deploy-subdirs

# pre-deployment does any necessary preparation for deployment.
#	deploy depends on it after all.  a site's depends.make may
#	add a dependency on deploy-subdirs to get a recursive deployment.
pre-deployment::
	@echo pre-deployment...

# deploy-only does a deployment (using git) but nothing else.
#	DEPLOY_OPTS can be used to add, e.g., --allow-empty
deploy-only::
	@if git remote | grep -s origin; then					\
	   git commit $(DEPLOY_OPTS) -a -m "Deployed from `hostname` `date`";  	\
	   git push origin | tee /dev/null;					\
	fi

# deploy-subdirs does pre-deployment and deploy-only in subdirectories.
#	It uses pre-deployment and deploy-only to avoid recursively doing
#	make all, which the top-level make deploy has already done.
deploy-subdirs::
	@echo deploying subdirectories
	@for d in $(SUBDIRS); do 					\
	     (cd $$d; @(MAKE) pre-deployment deploy-only) done

### git-related targets
#	Note that there is currently no way to override the following
#	targets with something from a local directory or tree.  If 
#	necessary we can make all this conditional on a flag variable.

# push:  do the subdirectories first.  Try make before resorting to git
#
push:: 
	@for d in $(GIT_DIRS); do 					\
	    if [ -d $$d/.git/refs/remotes/origin ]; then 		\
		echo pushing in $$d;					\
		(cd $$d; $(MAKE) push || git push | tee /dev/null); 	\
	    fi; 							\
	done

# push:	 This target does a snapshot "commit -a" before pushing.

push::  all
	@if git remote | grep -s origin; then			\
	   git commit -a -m "push from `hostname` `date`"  &&	\
	   git push origin | tee /dev/null;			\
	fi

pull:: 
	@for d in $(GIT_DIRS); do (cd $$d; 			\
	    echo pulling in $$d;				\
	    $(MAKE) pull || git pull origin : | tee /dev/null); \
	done
pull::
	@if [ -d .git/refs/remotes/origin ]; then 		\
	    git pull origin : | tee /dev/null; 			\
	fi


### DEPRECATED: Greatly simplified put target, using rsync to put the whole subtree.

.PHONY: put
put:: 	all
	rsync -a -z -v $(EXCLUDES) --delete $(RSYNC_FLAGS) \
	      ./ $(HOST):$(DOTDOT)/$(MYNAME)

### reporting

sloc.log:: 
	sloccount --addlang makefile . > $@

###### end of targets.make ######
