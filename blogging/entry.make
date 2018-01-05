### MakeStuff plugin for making and posting blog entries.
#

### Targets:
#	draft:	makes a draft entry in the top-level directory.  name-required
#	entry:	makes an entry directly in the destination directory.  symlinks .draft
#		to it; a name isn't required because it defaults to the day.
#       post:	post an entry.  Define POSTCMD if you have your own posting client.
#		if name isn't defined, uses the link in .draft if not posted yet.
#
# Note: you can define a name on the command line and it will override a default value
# in .config.make, e.g. time.  You can post an arbitrary file with make post ENTRY=<file>

draft_if_present := $(shell readlink .draft)
ifdef ENTRY
else
  ifdef name
    ENTRY := $(DAYPATH)--$(name).html
    ifndef title
	title := $(name)
    endif
  else
    ENTRY := $(shell readlink .draft)
  endif
endif

ifdef name
  DRAFT	:= $(name).html
endif

HELP  	  := make [entry|draft] name=<filename> [title="<title>"]
POST_HELP := make post name=<filename> [to=<post-url>]
POSTED	  := $(shell date) $(to)

# The command to post a file.
POSTCMD	= ljpost

### Targets
.PHONY: draft entry draft-or-entry-required name-or-entry-required name-required
.PHONY: pre-post post 

all:: 
	@echo To draft an entry, '$(HELP)'
	@echo ... then to post: ' $(POST_HELP)'

#
entry:  $(ENTRY) .draft

draft:	name-required $(DRAFT)

# make an entry for today
#	The commit gives us a record of the starting time.
#	the subject is, by default, today's date.
#
$(ENTRY):
	mkdir -p $(MONTHPATH)
	@echo "$$TEMPLATE" > $@
	git add $@
	git commit -m "$(MYNAME): started entry $(ENTRY)" $@

# make a draft in the top level.  No link is needed.
#	post with "make post name=<filename>"
$(DRAFT):
	@echo "$$TEMPLATE" > $@
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
	@if [ ! -f $(DRAFT) ] && [ ! -f $(ENTRY) ]; then			\
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

report-vars::
	echo name=$(NAME) ENTRY=$(ENTRY) DRAFT=$(DRAFT)

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

<p> 

endef

export TEMPLATE

### A little history:
#
#	This was derived from the depends.make -- formerly the Makefile -- in one
#	of my "private" journals.  Specifically, Private/Journals/River was one
#	of the two "journals" that were used primarily for Livejournal (later
#	Dreamwidth) entry drafts.
