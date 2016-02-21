### Makefile for Journals/River
#
#	This would work as a prototype for a generic set of blogging rules.

ENTRY   := $(DAYPATH)--$(name).html
DRAFT	:= $(name).html

HELP  	  := make [entry|draft] name=<shortname> [title="<title>"]
POST_HELP := make post name=<shortname> [to=<post-url>]

POSTED	:= $(shell date) $(to)

.PHONY: entry draft-required name-required

all:: 
	@echo you probably want '$(HELP)'
	@echo ... followed by '  $(POST_HELP)'

entry:  name-required $(ENTRY) .draft

draft:	name-required $(DRAFT)

# make an entry for today
#	The commit gives us a record of the starting time.
#	the subject is, by default, today's date.
#
$(ENTRY):
	mkdir -p $(MONTHPATH)
	@echo "$$TEMPLATE" > $@
	git commit -m "$(MYNAME): started entry $(ENTRY)" $@

# make a draft in the top level.  No link is needed.
#	post with "make post name=<filename>"
$(DRAFT):
	@echo "$$TEMPLATE" > $@

name-required:
	@if [ -z $(name) ]; then \
	   echo '$$(name) not defined.\n  Use "$(HELP)"'; false; \
	fi

draft-required:
	@if [ ! -f $(DRAFT) ] && [ ! -f $(ENTRY) ]; then			\
	    echo 'You need to "make draft|entry name=$(name)" first'; false;	\
	fi

# Record a post.
#	The double use of sed is to ensure that 
post:	name-required draft-required
	if [ -f $(DRAFT) ]; then git mv $(DRAFT) $(ENTRY); fi
	sed -i -e '1,/^$$/ { /^Posted:/ d }' $(ENTRY);
	sed -i -e '1,/^$$/ s/^$$/Posted:  $(POSTED)\n/' $(ENTRY);
	git add $(ENTRY)
	git commit -m "posted $(ENTRY)" $(ENTRY)

.PHONY: entry draft post name-required draft-required

# make .draft point to today's entry
.draft:: $(ENTRY)
	if [ -L $@ ]; then rm $@; else true; fi
	ln -s $< $@

define TEMPLATE
Subject: River: $(title)
Tags: river, 
Music: 
Mood: 
Access: public
Posted: 

<!-- notes: (removed from post)
  * $(ENTRY)
-->

<lj-cut text="raw notes">
<pre></pre>
</lj-cut>

<p> 
</p>
endef

export TEMPLATE
