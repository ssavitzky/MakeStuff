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

 [TeX/](TeX/) 
:   LaTeX styles for formatting FilkTeX ("`.flk`") files, plus the tools
    for translating them into HTML (`flktran.pl`) and generating index
    pages (`index.pl`). These are all showing their age, and need to be
    given an honorable retirement. In particular the LaTeX styles need
    to be updated for LaTeX 5e, and indexing needs to be done using Perl
    scripts derived from `TrackInfo.pl`.

 [deployment](deployment/) 
:   Git hooks and related tools for efficient website deployment.

 [include](include/) 
:   Files to be included in compilations or inserted into source code
    and documentation. Mostly contains various forms of license notice,
    in a format suitable for use with `boilermaker.pl`, and templates
    for use with `replace-template-file.pl`.

 [make](make/) 
:   The general-purpose `*.make` files included by `Makefile`.

 [music](music/) 
:   The `*.make` files and associated scripts used in music- and
    recording-related subdirectories and projects. Currently poorly
    integrated with FilkTex, and lightly documented.

 [scripts](scripts/) 
:   Short scripts and fragments, mostly having to do with setting up and
    maintaining subprojects using git.

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
:   Only in the top-level directory; this contains make rules,
    definitions, and dependencies that apply to the entire tree.

 `*/[.]depends.make` 
:   This also contains targets; if you have both, you can use this one
    for specific targets with dependencies.

### HEADER.html

Unlike most other directories on this website, where the `HEADER.html`
file is hidden from casual browsing by an `index.html` file, *this*
directory deliberately leaves `HEADER.html` out where you can see it.
Whenever I have control over a programming project, I make its directory
tree look like a website -- you will almost always find a `HEADER.html`
file like this one, in every subdirectory. The
[Apache](http://httpd.apache.org/docs-2.0/) web server puts a
`HEADER.html` file, if you have one, at the top of a directory listing.
(It puts `README.html` at the bottom, after the file list.) With a
little tweaking you can get similar behavior with plain-text `HEADER`
and `README`, but you can't always count on having enough control over a
hosted website's configuration.

This particular directory contains tools for working on website- and
music-related projects: the tools used on *this website* and the
projects you find here. (Source code for other, unrelated open-source
projects can be found in [../Src/](../Src/).)

### Other Files

 [`MIT-LICENSE.txt`](MIT-LICENSE.txt) 
:   What it says on the tin -- the license for this project and
    its contents.

 [`to.do`](to.do) 
:   The to-do list for this directory. You can probably find some in
    other directories if you look. The format is trivial: an open circle
    (lowercase "o") is something that's not finished yet; a filled
    circle (asterisk) is finished. "\~" indicates something I've decided
    not to do, and "?" indicates something I'm dithering about.
    Eventually finished items move to a "done" section or, when they
    start getting moldy, a separate file.

------------------------------------------------------------------------

[]()

------------------------------------------------------------------------
