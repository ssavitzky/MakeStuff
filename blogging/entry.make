### MakeStuff plugin for making and posting blog entries.
#
#	

### Targets:
#	draft:	makes a draft entry in the top-level directory.  name-required
#	entry:	makes an entry directly in the destination directory.  symlinks .draft
#		to it; a name isn't required because it defaults to the day.
#       post:	post an entry.  Define POSTCMD if you have your own posting client.
#
# Note: a name defined on the command line overrides a default value in .config.make, e.g. time.

ifdef name
    ENTRY := $(DAYPATH)--$(name).html
    ifndef title
	title := $(name)
    endif
else
    ENTRY := $(DAYPATH).html
endif

DRAFT	:= $(name).html

HELP  	  := make [entry|draft] name=<filename> [title="<title>"]
POST_HELP := make post name=<filename> [to=<post-url>]

POSTED	:= $(shell date) $(to)

# The command to post a file.
POSTCMD	= ljpost

### Targets
.PHONY: draft entry draft-or-entry-required name-required pre-post post 

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

draft-or-entry-required:
	@if [ ! -f $(DRAFT) ] && [ ! -f $(ENTRY) ]; then			\
	    echo 'You need to "make draft|entry name=$(name)" first'; false;	\
	fi

# Record a post.
#	The first use of sed deletes an empty "Posted:" header; it should perhaps
#	be optional so that a posting log is kept.  It's trivial to get it out of the
#	git log, though.
#	Note that git add is not needed because commit with a filename automatically
#	commits the current state of the file.
pre-post:	name-required draft-required
	-mkdir -p $(MONTHPATH)
	if [ -f $(DRAFT) ]; then git mv $(DRAFT) $(ENTRY); fi

post:	pre-post
	$(POSTCMD) $(ENTRY)
	sed -i -e '1,/^$$/ { /^Posted: *$$/ d }' $(ENTRY);
	sed -i -e '1,/^$$/ s/^$$/Posted:  $(POSTED)\n/' $(ENTRY)
	git commit -m "posted $(ENTRY)" $(ENTRY)

# make .draft point to today's entry
.draft:: $(ENTRY)
	if [ -L $@ ]; then rm $@; else true; fi
	ln -s $< $@

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
