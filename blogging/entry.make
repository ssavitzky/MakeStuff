### MakeStuff plugin for making and posting blog entries.
#
#	

### Targets for starting an entry:
#	draft:	makes a draft entry in the top-level directory.  name-required
#	entry:	makes an entry directly in the destination directory.  Leaves .draft symlinked
#		to it; a name isn't required because it defaults to the day.
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

HELP  	  := make [entry|draft] name=<shortname> [title="<title>"]
POST_HELP := make post name=<shortname> [to=<post-url>]

POSTED	:= $(shell date) $(to)

# The command to post a file.
POSTCMD	= ljpost

### Targets
.PHONY: draft entry draft-or-entry-required name-required post posted

all:: 
	@echo you probably want '$(HELP)'
	@echo ... followed by '  $(POST_HELP)'

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
posted:	name-required draft-required
	-mkdir -p $(MONTHPATH)
	if [ -f $(DRAFT) ]; then git mv $(DRAFT) $(ENTRY); fi
	sed -i -e '1,/^$$/ { /^Posted: *$$/ d }' $(ENTRY);
	sed -i -e '1,/^$$/ s/^$$/Posted:  $(POSTED)\n/' $(ENTRY)
	git commit -m "posted $(ENTRY)" $(ENTRY)

post:	posted
	$(POSTCMD) $(ENTRY)

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
