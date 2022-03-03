### Mixin for "Thankful Thursday" posts.
#
# Setup:	include $(TOOLDIR)/blogging/thanks.make
# Usage:	make thanks

.PHONY: thanks

### This illustrates using target-specific variables instead of invoking
#   make recursively with a new name= definition on the command line.
#
thanks: PFX   := thx_
thanks: NAME  := thankful-$(shell echo $(DAY) | tr [:upper:] [:lower:])
thanks: TITLE := Thankful $(DAY)
thanks: report-effective-vars entry

# NOTE:  by convention, PFX ends with an underscore.
define thx_TEMPLATE
Subject: $(TITLE)
Tags: thanks, 
Picture: turkey
Music: 
Mood: grateful
Location: $(DEFAULT_LOCATION)

<p> Today I am grateful for...

<ul>
  <li> 
</ul>
endef
