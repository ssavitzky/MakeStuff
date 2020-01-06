MakeStuff
=========

MakeStuff contains the Makefiles and associated scripts that I use to
build essentially all of my websites and projects, most notably
[steve.savitzky.net](http://steve.savitzky.net/). They have been
evolving over the course of several decades (the earliest recorded
commit dates back to 1994, and the tree was converted from CVS to git in
2010, but some of the scripts date back at least a decade earlier), so
they still contain a certain amount of cruft.

Annotated Contents
------------------

### Directories

 [blogging](blogging/) (see blogging/README.md for details.)
:   `blogging.make` provides make targets and templates for creating blog
	entries and posting them to Dreamwidth (a Livejournal clone) or Jekyll.
	It also includes support for activity logs (to.do and yyyy/mm.done).

 [deployment](deployment/) 
:   Git hooks and related tools for efficient website deployment.
    Mostly these are designed around a web host that can build the site
    from the the git working tree

 [make](make/) 
:   The general-purpose `*.make` files included by `Makefile`.

 [music](music/) 
:   The `*.make` files and associated scripts used in music- and
    recording-related subdirectories and projects.  These makefiles manage
    directories containing lyrics (in `.flk` format), and directories meant to
    be published on a website.  The latter have a subdirectory for every song;
    tags are used to determine which have web-visible lyrics.

 [scripts](scripts/) 
:   Short scripts and fragments, mostly having to do with setting up and
    maintaining subprojects using git.

 [TeX/](TeX/) 
:   LaTeX styles for formatting FilkTeX ("`.flk`") files, plus tools
    for translating them into HTML (`flktran.pl`) and generating index
    pages (`index.pl`).

### Makefile

Makefile is the heart and soul of MakeStuff. It's really just a
framework: it figures out where the MakeStuff directory is by looking up
the tree, and includes what it needs. It's designed so that you don't
have to maintain a separate Makefile in each subdirectory, just make a
symlink to the one in MakeStuff. Usually, the top-level Makefile in a
project is a symlink to `./MakeStuff/Makefile` and everything else links
to `../Makefile`.

The `Makefile` looks for the following local include files:

 `[.]site/config.make` 
:   Only in the top-level directory; this contains make rules,
    definitions, and dependencies that apply to the entire tree.

 `[.]site/targets.make` 
:   This contains rules and targets.

 `[.]site/depends.make` 
:   This also contains targets; if you have both, you can use this one
    for specific targets with dependencies.

 `*/[.]config.make` 
:   This contains make rules, definitions, dependencies, and `include`
	statements that apply to the current directory.  A local `.config.make` is
	_not_ inherited by subdirectories.  Files in `blogging`  and `music` are
	normally included here.

 `*/[.]depends.make` 
:   This contains make rules, definitions, and dependencies that apply to the
    current directory.  If you have both `config.make` and `depends.make`, you
    should use `depends.make` for specific targets with dependencies.

### HEADER.html

In addition to being on GitHub, this tree is designed so that it can easily be
published on a website.  The
[Apache](http://httpd.apache.org/docs-2.0/) web server puts a
`HEADER.html` file, if you have one, at the top of a directory listing;
and puts `README.html` at the bottom, after the file list.  With a
little tweaking you can get similar behavior with plain-text `HEADER`
and `README`, but you can't always count on having enough control over a
hosted website's configuration.

### Other Files

 [`MIT-LICENSE.txt`](MIT-LICENSE.txt) 
:   What it says on the tin -- the license for this project and
    its contents.

 [`to.do`](to.do) 
:   The to-do list for this project. The format is trivial: an open circle
    (lowercase "o") is something that's not finished yet; a filled
    circle (asterisk) is finished. "\~" indicates something I've decided
    not to do, and "?" indicates something I'm dithering about.
    Eventually finished items move to a "done" section or, when they
    start getting moldy, a separate file.

------------------------------------------------------------------------
