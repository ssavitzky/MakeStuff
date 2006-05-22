### Makefile for www/Steve_Savitzky/Tools
#	$Id: Makefile,v 1.4 2006-05-22 02:16:31 steve Exp $
# 	COPYRIGHT 2005, HyperSpace Express

TOPDIR=../../../..
MYNAME=Tools
DOTDOT=www/Steve_Savitzky
SRCDIR=../../.

FILES= README Makefile to.do	\
	list-tracks 		\
	Setlist.cgi		\
	$(wildcard *.pl)	\
	$(wildcard *.make) 	\
	$(wildcard *.html)

SUBDIRS= TeX

MF_DIR=$(TOPDIR)/Config/makefiles
include $(MF_DIR)/file.make
include $(MF_DIR)/webdir.make

