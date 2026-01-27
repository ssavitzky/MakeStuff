# FlkTex and conversion tools for song leadsheets

## Introduction

FlkTex is a LaTeX-based markup language for song leadsheets, of the sort used
by filkers, folk-singers, singer-songwriters, and other folks who just want
lyrics and chords so they can accompany themselves on guitars or other fretted
instruments.  The format uses chord symbols enclosed in square brackets and
embedded in the lyrics; this should be familiar to anyone who uses
[ChordPro](https://www.chordpro.org/) (which FlkTex predates by four or five
years -- `chord.c` was written in early 1987).

FlkTex differs from ChordPro its use of LaTeX constructs for both typesetting
and metadata; the typesetting parameters can usually be adjusted to fit an
entire song on a two-page spread (including _Desolation Row_).  Several
different variants are supported, for one- and two-sided printing.

The `flktran.pl` program in this directory can translate FlkTex into:

* ChordPro
* plain text, with or without chords
* HTML5 with or without chords.  Chords can be output either monospaced (in a
  `<pre>` element), or as a table.  Indentation of chorus and bridge sections
  is done using `<blockquote>`, which isn't ideal but it works.  HTML is
  output as a fragment, which can be included as a partial using a template
  engine, as an Apache server-side include file, or simply put together with
  header and footer files using `cat`.

The `songinfo` and `transpose` programs in `../music` also operate on FlkTex
files, and probably ought to be moved into this directory along with most or
all of `lyrics.make`.

## FlkTeX File Format

### Song Structure

Song structure is defined using LaTeX environments:

* `\begin{song}[options]{Title}` ... `\end{song}` encloses the entire song.
* `\makesongtitle` -- marks the end of the metadata, and should be followed by
  a blank line.  This lets us generate a title page.
	* `[S]` indicates that a song is "short", and can be typeset on a single
	  page. In a songbook, a short song can start (and end) on either an even
	  (left-hand) or an odd (right-hand) page.  (See below under Songbook
	  Styles.) 
	* `[L]` indicates that a song is "long", and that the lyrics need
	  to be printed on a two-page (even-odd) spread.  This is the default, but
	  is needed for songbooks in which the default has been reset using
	  `defaultsonglength{S}`. 
* `\begin{chorus}` ... `\end{chorus}` -- indented 1 em; `refrain` is a deprecated
  synonym for `chorus`.
* `\begin{bridge}` ... `\end{bridge}` -- indented 2em.
* `\begin{indent}` ... `\end{indent}` -- indented 4 em.
* `\begin{Indent}` ... `\end{Indent}` -- indented 6 em.
* `\begin{note}` ... `\end{note}` -- set flush left in smaller type, with
  normal line wrapping.
    * `\tailnote{text}` -- set text as a note forced to the bottom of the
	  page.
	* `\headnote{text}` -- a short note; basically the same as the note
	  environment except that it might be omitted in compact-format songbook
* `\\` or `\verse` -- separates verses.  Not needed before or after a chorus,
  bridge, or indented environment.

### Song Metadata

* `\subtitle{subtitle, set in smaller type}`
* `\notice{centered copyright notice}`
    * `\CcByNcSa`			% Creative Commons license
    * `\ttto{title}` -- to the tune of...
* `\dedication{centered dedication}`
* `\license{centered license}`
* `\description{description}` -- the description is not typeset in songbooks;
  it can be used for, e.g., CD and setlist liner notes.
* `\tags{tag1,tag2...}`	-- some tags (see below) are used to control website
  generation, e.g. by specifying which songs are safe to upload.
* `\key{C (A \capo 3)}` or `\key{A \capo 3}` -- The capo indication is
  optional; so are the parentheses if an actual key is omitted. ChordPro
  expects the key and capo to be separate metadata items.
* `\timing{mm:ss}`	-- timing.
* `\created{yymmdd}` -- creation date.
* `\cvsid{$Id ...}`	--  (obsolete) a CVS Id string.
* `\lyrics{lyricist}` -- lyricist (for track data).
* `\music{composer}` -- composer (for track data).
* `\arranger{arranger}`	-- arranger (for track data).
* `\performer{performer}` -- performer (for track data).
* `\credits{credits}` -- credits (for track data).
* `\performance{performance notes}` -- for future use on lead sheets for performers.

### Song Annotations

* `inset{text}` -- indent text 1em and set in italics.
* `inst{text}` -- for an instrumental section  -- text set in italics but not
  indented.
* `singer{text}` -- indent text .5em and set in a monospaced font, to indicate
  the singer of a verse or set of lines.  See below for a way of indicating
  singers on each line.
* `spoken{text}` -- spoken text; not indented; set in italics.

### Chords

As in ChordPro, chords are embedded in the lyrics, enclosed in square
brackets. A chord should start with a capital letter.  In particular, the
transpose program looks only at capital letters in brackets and key
directives.  This is also the convention in ChordPro. The following macros are
used as chord modifiers.

* `\sharp`, `\flat`, `\aug`, `\dim`, and `\add` -- use these instead of `#`,
  `b`, `+`, `o`, and `&`, respectively; that allows them to be rendered with
  the correct Unicode characters in HTML and PDF. In addition, `#` and `&`
  have special meanings in TeX.
* `\min`, `\maj`, `\sus` -- minor, major, and suspended respectively; `\min`
  is normally rendered as "m", as one would expect.  I've been known to
  redefine `\sus` to render as "s" for compactness in songs with a lot of
  suspended chords.  Similarly, one might render `\maj` as "M".
* `\capo` and `\drop` are used in key directives.  Thanks to TeX's peculiar
  syntax, no space is required after `\capo`.
* `\;` can be used to produce an em space inside of chord brackets that
  contain more than one chord; normally spaces are ignored.  It can
  occasionally be useful outside of chords as well, to prevent chords from
  overlapping. 

It's worth noting that LaTeX processes chords in a math context, which makes
it easy to do subscripts, superscripts (which you sometimes see used for
suspended chords), and symbols.


## Files

In addition to `song.sty`, which defines all of the above constructs, there
are two additional files that you will probably want to customize, although
default versions are provided.  They are overridden by files with the same
name in a lyrics directory, which makes them ideal for someone who is a member
of more than one group.

  * `zongbook.sty` -- defines headers, footers, margins, and other page
	parameters and features.
  * `zingers.sty` -- defines per-line singer annotations and can be used to
	override defaults set in `zongbook.sty`.  Singer annotations look like 
	  * `\X:` -- one or more letters between a backslash and a colon.  A
		single letter is typically the singer's initial.
	  * `\XY:` -- by convention, is X and Y singing the line together.
	  * `\A:` -- by convention is typeset as "ALL:", but it's easy to redefine
		it if somebody in your group is named Alex.
	All singer annotations are rendered in a fixed-width font, padded on the
	left with spaces, so that everything lines up.
  * `zongbook.tex` -- this is the source file for a full songbook.  Individual
	songs are included using `\file{songname.flk}`.
	
The substitution of "z" for "s" in `zongbook.*` etc. was originally done to
separate them from the songs in a directory listing.  Just how useful this is
depends on your OS's collating sequence.


## Layout

The way a song is laid out across pages is controlled by two parameters:
`twoside`, which is set as an option in the document header, and `compact`, a
boolean that determines how metadata is presented.  With `compact` false, a
title page is generated; with it true the title, copyright notice, etc. are
printed above the lyrics on the first page.

There are three main combinations; one combination, one-sided and not
compact, doesn't make any sense: 

  * **Looseleaf** -- two-sided, not compact.  This is the default for
	individual songs.  The first page is a "title page" with all of the
	metadata, and is forced to be a right-hand (odd-numbered) page.  That
	makes long songs come out with the lyrics on pages 2 and 3, facing each
	other. Short songs come out on a single sheet with the title page on the
	front and the lyrics on the back.  Looseleaf format is ideal for songbooks
	in three-ring binders; songs can be taken out, inserted, and re-arranged
	without having to reprint anything.
  * **Songbook** -- two-sided, compact.  This is designed for bound songbooks:
	any given two-page spread may contain up to two short songs, or one long
	one; a blank page (with headers and footers but no body) is inserted if
	necessary to make a long song start on an even page.  Tailnotes are
	omitted to save space.  Songbook format uses considerably less paper than
	looseleaf.
  * **Broadside** -- one-sided, compact.  This is a good format for
	printing one-sided, since it lets you put songs in a binder by simply
	flipping over the first page of every long song.  It's not bad as a format
	for downloadable songs on the web.




