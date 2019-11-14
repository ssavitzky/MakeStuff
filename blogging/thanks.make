### Mixin for "Thankful Thursday" posts.
#
# Setup:	include $(TOOLDIR)/blogging/thanks.make
# Usage:	make thanks

.PHONY: thanks
thanks:
	$(MAKE) entry PFX=thx_ name=thankful-$(shell date +%A | tr [:upper:] [:lower:])

# NOTE:  PFX is normally not defined, so we end it with an underscore.
define thx_TEMPLATE
Subject: Thankful $(shell date +%A)
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
