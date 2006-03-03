### Makefile for www/Steve_Savitzky/Tools
#	$Id: Makefile,v 1.3 2006-03-03 01:44:05 steve Exp $
# 	COPYRIGHT 2005, HyperSpace Express

TOPDIR=../../../..
MYNAME=Tools
DOTDOT=www/Steve_Savitzky
SRCDIR=../../.

FILES= README Makefile 		\
	list-tracks 		\
	$(wildcard *.make) 	\
	$(wildcard *.html)

MF_DIR=$(TOPDIR)/Config/makefiles
include $(MF_DIR)/file.make
include $(MF_DIR)/webdir.make

