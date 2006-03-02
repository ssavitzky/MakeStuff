### Makefile for www/Steve_Savitzky/Src
#	$Id: Makefile,v 1.1 2006-03-02 23:21:47 steve Exp $
# 	COPYRIGHT 2005, HyperSpace Express

TOPDIR=../../../..
MYNAME=Tools
DOTDOT=www/Steve_Savitzky
SRCDIR=../../.

FILES= README Makefile .htaccess \
	$(wildcard *.html)

MF_DIR=$(TOPDIR)/Config/makefiles
include $(MF_DIR)/file.make
include $(MF_DIR)/webdir.make

