### Makefile for www/Steve_Savitzky/Tools
#	$Id: Makefile,v 1.6 2007-07-17 06:16:51 steve Exp $
# 	COPYRIGHT 2005, HyperSpace Express

TOPDIR=../../../..
MYNAME=Tools
DOTDOT=www/Steve_Savitzky
SRCDIR=../../.

# It's important that .htaccess NOT be published to the web
#    It's used internally to activate locally-used CGIs.

FILES= README Makefile to.do	\
	list-tracks 		\
	Setlist.cgi		\
	$(wildcard *.pl)	\
	$(wildcard *.lsp)	\
	$(wildcard *.make) 	\
	$(wildcard *.html)

SUBDIRS= TeX

MF_DIR=$(TOPDIR)/Config/makefiles
include $(MF_DIR)/file.make
include $(MF_DIR)/webdir.make

