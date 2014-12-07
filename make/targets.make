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
#	Succeeds even if the push is not done: there may be additional
#	dependencies, such as rsync deployments.
# FIXME:  this only works for Tools itself because .. is git-controlled.
deploy-only:: | $(BASEDIR)/.git
	-@if git remote|grep -q origin && git branch|grep -q '* master'; then	\
	   git commit $(DEPLOY_OPTS) -a -m "pre-deployment commit";		\
	   if git status | head -2 | grep -q "branch is ahead of"; then		\
	   	git tag -a -m "Deployed from `hostname` `date`";		\
	   	git push origin | tee /dev/null;				\
	   else echo "git deployment not needed: up to date";			\
	   fi									\
	elif git remote|grep -q origin; then					\
	   echo "not on branch master; not deploying.";				\
	fi

# deploy-subdirs does pre-deployment and deploy-only in subdirectories.
#	It uses pre-deployment and deploy-only to avoid recursively doing
#	make all, which the top-level make deploy has already done, but
#	blythely assumes that a deploy target implies their existance.
deploy-subdirs::
	@echo deploying subdirectories
	@for d in $(SUBDIRS); do grep -qs deploy: $$d/Makefile &&		\
	     (cd $$d; @(MAKE) pre-deployment deploy-only) done

### older git-related targets
#	Note that there is currently no way to override the following
#	targets with something from a local directory or tree.  Deploy
#	is better than push for this reason.

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
#	 It doesn't push if the commit fails.
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


### Test - list important variables

.PHONY: test
V1 := BASEDIR MYNAME 
V2 := BASEREL TOOLREL 
V3 := HOST DOTDOT 
test::
	@echo $(foreach v,$(V1), $(v)=$($(v)) )
	@echo $(foreach v,$(V2), $(v)=$($(v)) )
	@echo $(foreach v,$(V3), $(v)=$($(v)) )
	@echo FILES: $(FILES)
	@if [ "$(SUBDIRS)" != "" ]; then echo SUBDIRS: $(SUBDIRS); fi
	@echo items: $(ITEMDIRS)
	@echo colls: $(COLLDIRS)
	@echo git: $(GIT_DIRS)

### Setup


### Fixup

# link-makefile - link a Makefile from Tools.
.PHONY: link-makefile
link-makefile: 
	if [ ! -L Makefile ]; then 				\
	   if [ -f Makefile ]; then git rm -f Makefile; fi; 	\
	   ln -s $(TOOLREL)/Makefile .; 			\
	   git add Makefile; 					\
	   git commit -m "Makefile linked from Tools"; 		\
	fi

###### end of targets.make ######
