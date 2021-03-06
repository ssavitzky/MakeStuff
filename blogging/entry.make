### MakeStuff plugin for making and posting blog entries.
#
# Usage:  include $(TOOLDIR)/blogging/entry.make

### Targets:
#	draft:	makes a draft entry in the top-level directory.  name-required
#	entry:	makes an entry directly in the destination directory.  symlinks .draft
#		to it so that you can post without specifying a name.  Typically used
#		when you are reasonably sure that you will be posting the same day.
#       post:	post an entry.  Define POSTCMD if you have your own posting client.
#		if name isn't defined, uses the link in .draft.
#
# Note: You can post an arbitrary file with make post ENTRY=<file>
#	A default name can be defined in .config.make and overridden on the command line.
#
# Tweakable Parameters:
#       DONT_COMMIT_DRAFT if defined, just add the draft without committing it.
#	POST_ARCHIVE 	- if defined, this is the path to yyyy/...; it must end in /
#		          Typically this will be ../ (slash required).  Defaults to empty
#	DRAFTS	     	- if defined, directory where we keep drafts.  Used with Jekyll.
#	EXT	     	- Filename extension.  Default is html; md is a popular alternative.
#	PFX	     	- prepended to the template name.  See thanks.make for an example.
#
#	POSTCMD		- command to post; currently charm-wrapper, a wrapper for ljcharm

### Defaults

# The default default extension is html; this lets us override the default in .config.make
DEFAULT_EXT ?= html
POSTCMD	?= $(TOOLDIR)/blogging/charm-wrapper
#DONT_COMMIT_DRAFT = true
export POST_ARCHIVE

HELP  	  := make [entry|draft|post] [name=<filename>] [title="<title>"]

### DRAFT, ENTRY, draft, and entry
#
### Determine name, extension, and title; DRAFT and ENTRY
#   There are several different possibilities
#   * name was defined on the command line.  It might have an extension, either from
#     tab completion or because we want to use something other than the default
#   * name wasn't defined, but title was, so we slugify it to get the name.
#   * ENTRY was passed on the command line.  DRAFT is irrelevant.
#   * there's a symlink called .draft.  It can point to either a draft file in this
#     directory, or a entry under construction; we use it to define ENTRY and DRAFT
#   * there's a default name

ifdef name
  ifneq "$(suffix $(name))" "" # take the extension from the name, if it has one.
    EXT := $(subst .,,$(suffix $(name)))
    override name := $(basename $(notdir $(name)))
  endif
  ifndef title			# If we don't have a title, unslugify the name
    title := $(shell echo "$(name)" | tr '-' ' ' )
  endif
else ifdef title		# if we have a title but no name, slugfy the title
  name := $(shell echo "$(title)" | 						\
	    sed  -e 's/"//g' -e 's/\[.*\]//' 					\
		 -e 's/[ -]\+/-/g' -e 's/^-*//'  -e s/-*$$// 			\
		 -e 's/[^-a-zA-Z0-9]//g' -e 's/^the-//i' | tr '[A-Z]' '[a-z]')
else ifdef entry		# entry was defined on the command line
  EXT := $(subst .,,$(suffix $(entry)))
  name := $(basename $(entry))
else ifneq "$(strip $(shell test -f .draft || echo 1))" "1" # .draft is a (live) symlink
  linked_draft := $(shell readlink .draft)
  ifneq "$(dir $(linked_draft))" "./"
    # if .draft points to an entry, we use it as $(entry).  Otherwise it points to a draft
    # file in the current directory, and entry is derived by appending its name to
    # `$(DAYPATH)--`
    $(info using linked draft $(linked_draft) as entry)
    entry = $(linked_draft)
    draft = $(notdir $(linked_draft))
  else
    entry = $(POST_ARCHIVE)$(DAYPATH)--$(linked_draft)
    $(info constructing entry $(entry) from $(linked_draft))
    draft = $(linked_draft)
  endif
else ifdef DEFAULT_NAME
  name := $(DEFAULT_NAME)
endif

# Use the default extension if it isn't defined.  This also handles the case where
# EXT was defined as the suffix of something that doesn't have one.
ifeq ($(EXT),)
    EXT := $(DEFAULT_EXT)
endif

# NAME starts out as the value of $(name) (or sluggified title) defined on the 
#   command line.  It may be replaced by a target-specific variable; this
#   avoids having to override the value of $(name), and is more consistent with
#   PFX and EXT.  Note that we ignore the convention that makes uppercase names
#   constants or configuration parameters and lowercase names internal variables,
#   because defining uppercase names on the command line is annoying.

NAME  := $(name)

# TITLE, similarly, starts out with the title defined on the command line.
#   Most templates and shortcuts play fast-and-loose with it and use $(title);
#   this is a legacy usage, but as long as the template and the shortcut match
#   it doesn't matter.  The main default template uses TITLE, and there are
#   probably still some shortcuts that are incorrect because of that.

TITLE := $(title)

### Define DRAFT and ENTRY
#   $(DRAFT) and $(ENTRY) are the targets of `make draft` and `make entry` respectively.
#   They depend on $(NAME), which might be a target-specific value that replaces or
#   modifies the $(name) passed on the command line.  Their values do _not_ depend
#   on a possible `.draft` symlink; this is considerably more consistent than the
#   alternative.

DRAFT ?= $(NAME).$(EXT)
ENTRY ?= $(POST_ARCHIVE)$(DAYPATH)--$(NAME).$(EXT)

### Define draft and entry
#   $(entry) and $(draft) are the inputs to the posting recipes; they come from
#   entry= defined on the command line, a name and/or title passed on the command
#   line, or a `.draft` symlink if it exists and nothing was defined on the command
#   line.  They depend on $(name), the value defined on the command line.
draft ?= $(name).$(EXT)
entry ?= $(POST_ARCHIVE)$(DAYPATH)--$(name).$(EXT)

POSTED	   = $(subst /,-,$(DAYPATH)) $(HRTIME)

### Targets ###

.PHONY: draft entry pre-post post report-effective-vars
.PHONY: from-required draft-or-entry-required name-or-entry-required name-required

help:: 
	@echo usage: '$(HELP)'

# Useful debugging tool:  Add as a dependency to a target with target-specific vars.
# 	see ./thanks.make for an example.
#
report-effective-vars:
	@echo "name =" $(name),  title = '\"$(title)\"'
	@echo "draft=" $(draft), entry = $(entry)
	@echo "NAME =" $(NAME),  TITLE = '\"$(TITLE)\"'
	@echo "DRAFT=" $(DRAFT), ENTRY = $(ENTRY) from command or target

## entry:  make an entry for today, and link .draft
#	The commit gives us a record of the starting time.
#	the subject is, by default, today's date.
#	Leaves .draft a symlink to the entry; name= is not required for posting.
#
entry: 	name-required | $(POST_ARCHIVE)$(MONTHPATH)
	[ ! -f $(ENTRY) ] || ( echo entry already exists; false )
	echo "$$$(PFX)TEMPLATE" > $(ENTRY)
	git add $(ENTRY)
	git commit -m "$(MYNAME): start $(ENTRY)" $(ENTRY)
	ln -sf $(ENTRY) .draft

## draft:  make a draft in the top level.
#	No link is needed.  post with "make post name=<filename>"
#	name is required in this case -> hopefully not any more.
#
draft:	name-required
	echo "$$$(PFX)TEMPLATE" > $(DRAFT)
	git add $(DRAFT)
	[ ! -z $(DONT_COMMIT_DRAFT) ] || 					\
	   git commit -m "$(MYNAME): start $(DRAFT) on $(DAYPATH)" $(DRAFT)

## Validation dependencies for posting:
#
#	Multiple drafts can occur if drafts are kept in a separate directory;
#	that's the case in Jekyll blogs for example.

#	name-required is a dependency of entry and draft; it checks $(NAME),
#	but suggests $(name) because name=xxx is what goes on the commad line.
name-required:
	@if [ -z $(NAME) ]; then \
	   echo '$$(name) not defined.\n  Use "$(HELP)"'; false; \
	fi

#	name-or-entry-required does not appear to be in use, and will probably
#	go away at some point unless it acquires one.
name-or-entry-required:
	@if [ -z $(name) ] && [ ! -f $(entry) ]; then \
	   echo '$$(name) not defined.\n  Use "$(HELP)"'; false; \
	fi

draft-or-entry-required:
	@if [ ! -f $(draft) ] && [ ! -e $(entry) ]; then			\
	    echo 'You need to "make draft|entry name=$(name)" first'; false;	\
	elif [ "multiple-drafts" = "$(draft)" ]; then				\
	   echo 'More than one file in _drafts;'				\
		'Specify one with name='; false; 				\
	fi

# This would be used by import.
from-required:
	@if [ -z $(from) ]; then 			\
	   echo '$$(from) not defined."'; false; 	\
	fi

## rules for date-related directories

# This is a prerequisite for entry;
ifdef POST_ARCHIVE
$(POST_ARCHIVE)$(MONTHPATH):
	mkdir -p $@
endif

$(MONTHPATH):
	mkdir -p $@

$(YYYY):
	mkdir $@
	ln -s ../Makefile $@

# pre-post:  move the entry to the correct location (yyyy/mm/dd--name) if necessary
#	The entry is not committed; that's done in post, but if it hasn't been added
#	git mv will fail and we do a plain mv followed by git add.
#
#	Ensure that a .draft link to the new entry exists, e.g. if it was created
#	with an earlier "make draft".  The .draft link stays around until you
#	"make post", so that it won't require a name= if it's done separately,
#	e.g. for appending an accurate word count.  It works because pre-post is
#	idempotent.
#
pre-post:  draft-or-entry-required | $(POST_ARCHIVE)$(MONTHPATH)
	if [ ! -f $(entry) ]; then mkdir -p $(POST_ARCHIVE)$(MONTHPATH); 	   \
	   git mv $(draft) $(entry) || ( mv  $(draft) $(entry); git add $(entry) ) \
	fi
	ln -sf $(entry) .draft

# post an entry.
#	The date is recorded in the entry, followed by the url returned by $(POSTCMD).
#
#	We verify that $(POSTCMD) actually _does_ return a URL.  Earlier, we were
#	dumping charm's output to /dev/null; now the hope is that it might
#	eventually return a URL, and in any case we need to see any error messages
#	it prints.  We now do the right thing and test POSTCMD's output to see
#	whether it starts with a URL, and run ./last-post to get it if it doesn't.
#	That means that we can stop trying to do it in charm-wrapper.
#
#	We commit with -a because the draft might have been added but not committed;
#	in that case we can't rely on `git mv` having noticed the deletion.
#
#	Assuming the post succeeded, remove the .draft link and replace it with
#	.post, which makes the most recent entry easier to find for editing.
#
#	Finally, grep for the Posted: line, which gets the URL printed on the
#	terminal; most terminal emulators, e.g. gnome-terminal, let you open it.
#	Use tail on grep's results, to get the most recent Posted: line
#
post:	pre-post
	url=$$($(POSTCMD) $(entry)); echo posting returned :$$url:;	\
	echo "$$url" | grep -q -E '^(http|file|[0-9./])' 		\
	     || url=$$($(TOOLDIR)/blogging/last-post $(JOURNAL));	\
	sed -i -e '1,/^$$/ s@^$$@Posted:  $(POSTED) '"$$url"'\n@' $(entry)
	rm -f .draft
	ln -sf $(entry) .post
	git add $(entry)
	git commit -m "posted $(entry)" -a
	grep Posted: $(entry) | tail -1

# crosspost the latest post to LJ, for use when automatic crossposting is broken
# this is fragile: it relies on there being two spaces after "Posted:"
LAST_POST = $(shell if [ -e $(entry) ]; then echo $(entry); else readlink .post; fi)
POSTED_URL = $(shell grep Posted: $(LAST_POST) | head -1 | cut -f5 -d' ')
CROSSPOSTED = <p> Cross-posted from <a href=$(POSTED_URL)>$(JOURNAL)</a>

xpost:
	(sed -e 's/<cut/<lj-cut/' -e 's@</cut@</lj-cut@' $(LAST_POST); \
		echo "$(CROSSPOSTED)") | $(POSTCMD) -x

# record posted date in an entry, assuming something went wrong posting it
#
POST_URL=$(shell wget -q -O - https://$(JOURNAL)/$(DAYPATH)  	\
         | grep 'class="entry-title"' | tail -1                 \
         | sed -E 's/^<[^>]*><[^>]*href="([^"]*)".*$$/\1/')
posted:
	url=$$($(TOOLDIR)/blogging/last-post $(JOURNAL)); 	\
	echo url=:$$url:; 			\
	sed -i -e '1,/^$$/ s@^$$@Posted:  $(POSTED) '"$$url"'\n@' $(entry)
	git commit -m "posted $(entry)" $(entry)
	rm -f .draft
	ln -sf $(entry) .post
	grep Posted: $(entry) | tail -1

#	sed -i -e '1,/^$$/ s@^$$@Posted:  $(POSTED) $(POST_URL)\n@' $(entry)

# make .draft point to today's entry
.draft:: $(ENTRY)
	ln -sf $< $@

### Operations involving un-posted entries.
#	RECENT_ENTRIES contains the names of all entries in the last 2 months.
#	look back that far because we might be at the start of a month.
#	Use the fact that valid months and entries start with a digit.
RECENT_ENTRIES = $(shell for m in $$(ls -d $(POST_ARCHIVE)2*/[0-9]* | tail -2); \
			     do ls $$m/[0-9]*; done)
#	RECENT_DRAFTS is the (possibly empty) set of entries that haven't been posted
RECENT_DRAFTS  = $(shell for g in $(RECENT_ENTRIES); \
			     do grep -q Posted: $$g || echo $$g; done)
MOST_RECENT_DRAFT = $(lastword $(RECENT_DRAFTS))

## redraft:  (retrieve draft) Set .draft to the most recent unposted entry, if any.
#	This is can be used to set .draft after pulling a commit that contains a
#	draft entry; it is also a dependency of updraft, used to make sure that
#	iff .draft exists it points to the most recent unposted entry.
.PHONY: redraft updraft
redraft:
	@most_recent_draft=$(MOST_RECENT_DRAFT);			\
	if [ ! -z "$$most_recent_draft" ]; then				\
	    ln -sf $$most_recent_draft .draft;				\
	    echo .draft '->' `readlink .draft` '(most recent entry)';	\
	else								\
	    echo there are no unposted entries to link;			\
	    rm -f .draft;						\
	fi

## updraft:  Move the most recent draft, if any, to today's path
#	This can be used a day or two after starting a draft with `make entry` in
#	order to make the path match the posting date.  Could consider making it
#	a dependency of `make post`.
updraft:  redraft
	@if [ -e .draft ]; then							\
	    if readlink .draft | grep -q $(DAYPATH); then			\
	      echo current .draft is `readlink .draft`;				\
	    else								\
	      today=$$(readlink .draft 						\
		      | sed -E s@[0-9]{4}/[0-9][0-9]/[0-9][0-9]@$(DAYPATH)@);	\
	      mv $$(readlink .draft) $$today;					\
	      ln -sf $$today .draft;						\
	      echo .draft "->"`readlink .draft`;				\
	    fi									\
	else									\
	    echo no .draft to update;						\
	fi

### reporting

.PHONY: report-template wc wc-month wc-prev xp-text check
wc:
	$(TOOLDIR)/blogging/word-count

wc-v:
	$(TOOLDIR)/blogging/word-count -v

wc-last:
	$(TOOLDIR)/blogging/word-count -v `date -d "today - 1month" +%m`

xp-text:
	echo "$(CROSSPOSTED)"

check:
	@[ -L .draft ] || (echo .draft does not exist && false)
	$(TOOLDIR)/blogging/check-html .draft


reportVars += name title entry draft ENTRY DRAFT EXT
report-template:
	@echo "$$TEMPLATE"

# The default entry template.
#     A redefinition in .config.make will silently override it
define TEMPLATE
Subject: $(TITLE)
Access: public
Tags: 
Music: 
Mood: 
Location: $(DEFAULT_LOCATION)
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
