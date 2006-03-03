### Makefile for www/Steve_Savitzky/Src
#	$Id: Makefile,v 1.2 2006-03-03 00:18:22 steve Exp $
# 	COPYRIGHT 2005, HyperSpace Express

TOPDIR=../../../..
MYNAME=Tools
DOTDOT=www/Steve_Savitzky
SRCDIR=../../.

FILES= README Makefile \
	$(wildcard *.html)

MF_DIR=$(TOPDIR)/Config/makefiles
include $(MF_DIR)/file.make
include $(MF_DIR)/webdir.make

