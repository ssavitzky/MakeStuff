### Makefile for Journals/River
#

DAYPATH = $(shell date "+%Y/%m/%d")
MONTHPATH = $(shell date "+%Y/%m")
TEMPLATE = 0template.html
ENTRY = $(DAYPATH)--$(name).html

.PHONY: all entry

all:: 
	@echo you probably want '"make entry name=<shortname>"'

entry:  $(ENTRY) .draft

# make an entry for today
#	The commit gives us a record of the starting time.
#	the subject is, by default, today's date.
#
$(ENTRY): 
	@if [ -z $(name) ]; then \
	   echo '$$(name) not defined.  Use name="..."'; false; \
	fi
	mkdir -p $(MONTHPATH)
	cp $(TEMPLATE) $@
	git add $@
	git commit -m "started from $(TEMPLATE)" $@

# make .draft point to today's entry
.draft:: $(ENTRY)
	if [ -L $@ ]; then rm $@; else true; fi
	ln -s $< $@

