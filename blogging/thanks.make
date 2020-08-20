### Mixin for "Thankful Thursday" posts.
#
# Setup:	include $(TOOLDIR)/blogging/thanks.make
# Usage:	make thanks

.PHONY: thanks

### This illustrates using target-specific variables instead of invoking
#   make recursively with a new name= definition on the command line
thanks: PFX=thx_
thanks: name=thankful-$(shell date +%A | tr [:upper:] [:lower:])
thanks: title = Thankful $(shell date +%A)
thanks: entry

# NOTE:  PFX is normally not defined, so we end it with an underscore.
define thx_TEMPLATE
Subject: $(title)
Tags: thanks, 
Picture: turkey
Music: 
Mood: grateful

<p> Today I am grateful for...

<ul>
  <li>
</ul>
endef
export thx_TEMPLATE
