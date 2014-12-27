#!/usr/bin/make  ### targets.make - basic targets for makefiles
#
# This file is meant to be included by Tools/Makefile, and defines a
# generally-useful collection of targets.
#
# Note that targets in this file will not be found by bash autocomplete. 


### deployment

.PHONY: pre-deploy deploy-this deploy-r

# pre-deploy does any necessary preparation for deployment.
#	deploy depends on it after all.  a site's depends.make may
#	add a dependency on deploy-subdirs to get a recursive deployment.
pre-deploy::
	@echo pre-deploy...

# deploy-this does a deployment (using git) but nothing else.
#	DEPLOY_OPTS can be used to add, e.g., --allow-empty
#	Succeeds even if the push is not done: there may be additional
#	dependencies, such as rsync deployments.
# FIXME:  this only works for Tools itself because .. is git-controlled.
deploy-this:: | $(BASEDIR)/.git
	-@if git remote|grep -q origin && git branch|grep -q '* master'; then	\
	   git commit $(DEPLOY_OPTS) -a -m "Deployed from `hostname` `date`";	\
	   if git diff --quiet origin/master; then				\
		echo "git deployment not needed: up to date";			\
	   else									\
	   	git push --tags origin master | tee /dev/null;			\
	   fi									\
	elif git remote|grep -q origin; then					\
	   echo "not on branch master; not deploying.";				\
	fi

# deploy-tag should be done explicitly in most cases.
deploy-tag::
	@echo tagging deployment
	git tag -a -m "Deployed from `hostname` `date`"				\
	       deployed/`date -u +%Y%m%dT%H%M%SZ`;
	git push --tags | tee /dev/null

# deploy-r does pre-deploy and deploy-this in subdirectories.
#	It uses pre-deploy and deploy-this to avoid recursively doing
#	make all, which the top-level make deploy has already done, but
#	blythely assumes that a deploy target implies their existance.
deploy-r::
	@echo deploying subdirectories
	@for d in $(SUBDIRS); do grep -qs deploy: $$d/Makefile &&		\
	     (cd $$d; $(MAKE) pre-deploy deploy-this) done

# push is essentially the same as (git-only) deploy except that
#	* it does not create a tag, nor does it push them.
#	* it doesn't verify that master is the current branch.
#	* it recurses automatically into git-controled subdirectories,
#	* ...but doesn't require a makefile there.

.PHONY: push push-this push-r

push:	all push-this push-r

push-this:: | $(BASEDIR)/.git
	-@if git remote|grep -q origin; then					\
	   git commit -a  $(PUSH_OPTS) -m "Pushed from `hostname` `date`";	\
	   git push | tee /dev/null;						\
	fi

push-r::
	@for d in $(GITDIRS); do 					\
	    if [ -d $$d/.git/refs/remotes/origin ]; then 		\
		echo pushing in $$d;					\
		(cd $$d; $(MAKE) push-this || git push|tee /dev/null);	\
	    fi; 							\
	done

# pull does pull --rebase

pull::
	@if [ -d .git/refs/remotes/origin ]; then 		\
	    git pull --rebase | tee /dev/null; 			\
	fi

pull:: 
	@for d in $(GITDIRS); do (cd $$d; 			\
	    echo pulling into $$d;				\
	    $(MAKE) pull || git pull --rebase | tee /dev/null); \
	done


### DEPRECATED: Greatly simplified put target, using rsync to put the whole subtree.

.PHONY: put
put:
	@echo deprecated:  use deploy or rsync;	false

rsync:
	rsync -a -z -v $(EXCLUDES) --delete $(RSYNC_FLAGS) \
	      ./ $(HOST):$(DOTDOT)/$(MYNAME)

### reporting

.PHONY: sloc-count status
sloc-count: sloc.log
	cat sloc.log

sloc.log:: 
	sloccount --addlang makefile . > $@

status:
	echo git status for $(MYNAME) and subdirs
	@$(TOOLDIR)/scripts/git-status-all


### report-vars - list important make variables

.PHONY: report-vars
V1 := BASEDIR MYNAME 
V2 := BASEREL TOOLREL 
V3 := HOST DOTDOT 
report-vars::
	@echo SHELL=$(SHELL)
	@echo $(foreach v,$(V1), $(v)=$($(v)) )
	@echo $(foreach v,$(V2), $(v)=$($(v)) )
	@echo $(foreach v,$(V3), $(v)=$($(v)) )
	@echo FILES: $(FILES)
	@if [ "$(SUBDIRS)" != "" ]; then echo SUBDIRS: $(SUBDIRS); fi
	@if [ "$(GITDIRS)" != "" ]; then echo GITDIRS: $(GITDIRS); fi
	@echo Colls: $(COLLDIRS)
	@echo dates: $(DATEDIRS)
	@echo items: $(ITEMDIRS)

### Setup

.PHONY: deployable remote-repo

deployable: .git .git/refs/remotes/origin
	$(TOOLDIR)/scripts/init-deployment

remote-repo:  .git/refs/remotes/origin

.git/refs/remotes/origin:
	$(TOOLDIR)/scripts/init-remote-repo

### Fixup

# makeable - link a Makefile from Tools.
#	This will also fix a broken Makefile link
.PHONY: makeable
makeable: 
	if [ ! -L Makefile -o ! -e Makefile ]; then 		\
	   if [ -f Makefile ]; then git rm -f Makefile; fi; 	\
	   ln -s $(TOOLREL)/Makefile .; 			\
	   git add Makefile; 					\
	   git commit -m "Makefile linked from Tools"; 		\
	fi

###### end of targets.make ######
