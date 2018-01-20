### MakeStuff plugin for making and posting blog entries.
#
# Usage:  include $(TOOLDIR)/blogging/entry.make

### Targets:
#	draft:	makes a draft entry in the top-level directory.  name-required
#	entry:	makes an entry directly in the destination directory.  symlinks .draft
#		to it so that you can post without specifying a name.
#       post:	post an entry.  Define POSTCMD if you have your own posting client.
#		if name isn't defined, uses the link in .draft.
#
# Note: You can post an arbitrary file with make post ENTRY=<file>
#	A default name can be defined in .config.make and overridden on the command line.
#
# Tweakable Parameters:
#	DEFAULT_NAME - if defined, it's used if name is not defined on the command line
#	POST_ARCHIVE - if defined, this is the path to the yyyy/... post archive directories.
#		       Typically this will be ../ (slash required)
#	PFX	     - prepended to the template name

linked_draft := $(shell readlink .draft)
ifndef ENTRY
  ifdef name
    ENTRY := $(POST_ARCHIVE)$(DAYPATH)--$(name).html
    ifndef title
	title := $(name)
    endif
  else ifneq ($(linked_draft),)
    ENTRY := $(linked_draft)
  else ifeq ($(DEFAULT_NAME),)
      ENTRY := $(POST_ARCHIVE)$(DAYPATH)
  else
      ENTRY := $(POST_ARCHIVE)$(DAYPATH)--$(DEFAULT_NAME).html
  endif
endif

ifdef name
  DRAFT	:= $(name).html
endif

HELP  	  := make [entry|draft] name=<filename> [title="<title>"]
POST_HELP := make post [name=<filename>] [to=<post-url>]
POSTED	  := $(shell date) $(to)

# The command to post a file.
POSTCMD	= ljpost

### Targets ###

.PHONY: draft entry draft-or-entry-required name-or-entry-required name-required
.PHONY: pre-post post 

all:: 
	@echo To draft an entry, '$(HELP)'
	@echo ... then to post: ' $(POST_HELP)'

## entry:  make an entry for today, and link .draft
#	The commit gives us a record of the starting time.
#	the subject is, by default, today's date.
#	Leaves .draft a symlink to the entry; name= is not required for posting.
#
entry:  $(ENTRY) .draft

## draft:  make a draft in the top level.  No link is needed.
#	post with "make post name=<filename>"; name is required in this case
#
draft:	name-required $(DRAFT)

$(ENTRY):
	mkdir -p $(MONTHPATH)
	@echo "$$$(PFX)TEMPLATE" > $@
	git add $@
	git commit -m "$(MYNAME): started entry $(ENTRY)" $@

$(DRAFT):
	@echo "$$$(PFX)TEMPLATE" > $@
	git add $@
	git commit -m "$(MYNAME): started entry $(ENTRY)" $@

name-required:
	@if [ -z $(name) ]; then \
	   echo '$$(name) not defined.\n  Use "$(HELP)"'; false; \
	fi

name-or-entry-required:
	@if [ -z $(name) ] && [ ! -f $(ENTRY) ]; then \
	   echo '$$(name) not defined.\n  Use "$(HELP)"'; false; \
	fi

draft-or-entry-required:
	@if [ ! -f $(DRAFT) ] && [ ! -e $(ENTRY) ]; then			\
	    echo 'You need to "make draft|entry name=$(name)" first'; false;	\
	fi

# pre-post:  move the entry to the correct location (yyyy/mm/dd--name) if necessary
#	The entry is not committed; that's done in post
pre-post:	name-or-entry-required draft-or-entry-required
	if [ ! -f $(ENTRY) ]; then mkdir -p $(MONTHPATH); git mv $(DRAFT) $(ENTRY); fi

# post an entry.
#	The date is recorded in the entry; it would be easy to modify this to
#	add the url if POSTCMD was able to return it.
post:	pre-post
	$(POSTCMD) $(ENTRY)
	sed -i -e '1,/^$$/ s/^$$/Posted:  $(POSTED)\n/' $(ENTRY)
	git add $(ENTRY)
	git commit -m "posted $(ENTRY)"
	rm -f .draft

posted:
	sed -i -e '1,/^$$/ s/^$$/Posted:  $(POSTED)\n/' $(ENTRY)
	git commit -m "posted $(ENTRY)" $(ENTRY)

# make .draft point to today's entry
.draft:: $(ENTRY)
	if [ -L $@ ]; then rm $@; else true; fi
	ln -s $< $@

reportVars := $(reportVars) name ENTRY DRAFT

report-template:
	@echo "$$TEMPLATE"

# The default entry template.
#     A redefinition in .config.make will silently override it
define TEMPLATE
Subject: $(title)
Access: public
Tags: 
Music: 
Mood: 
Location:
Picture:

<p> 

endef

export TEMPLATE

### A little history:
#
#	This was derived from the depends.make -- formerly the Makefile -- in one
#	of my "private" journals.  Specifically, Private/Journals/River was one
#	of the two "journals" that were used primarily for Livejournal (later
#	Dreamwidth) entry drafts.
