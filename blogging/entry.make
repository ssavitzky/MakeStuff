### Makefile for Journals/River
#

DAYPATH   := $(shell date "+%Y/%m/%d")
MONTHPATH := $(shell date "+%Y/%m")
ENTRY     := $(DAYPATH)--$(name).html

HELP  := make entry name=<shortname> [title="<title>"]

.PHONY: all entry

all:: 
	@echo you probably want '$(HELP)'

entry:  $(ENTRY) .draft

# make an entry for today
#	The commit gives us a record of the starting time.
#	the subject is, by default, today's date.
#
$(ENTRY)::
	@if [ -z $(name) ]; then \
	   echo '$$(name) not defined.  Use name="..."'; false; \
	fi
	mkdir -p $(MONTHPATH)
	echo "$$TEMPLATE" $@

commit:
	git add $(ENTRY)
	git commit -m "$(ENTRY) started" $(ENTRY)

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
