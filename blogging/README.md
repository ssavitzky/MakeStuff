## Blogging with MakeStuff

The blogging rules are not loaded by default; you create a blog directory by
making a file called `.config.make` with the following line:

```
include $(TOOLDIR)/blogging/entry.make
```

That gives you the three main `make` targets:

```
make [entry|draft] name=<filename> [title="<title>"]
make post [name=<filename>] [to=<post-url>]
```

### Here's how it works:

Blog entries are stored in files (under the blog directory, although you can
change this by setting `POST_ARCHIVE` in `.config.make`) with names like
```
./yyyy/mm/dd--<filename>.html
```

The `<filename>` comes from the initial make command.  The difference between
the `entry` and `draft` targets is that `make entry` creates the entry with
the complete filename, whereas `make draft` makes a file called
`<filename>.html` in the current directory.  You use `entry` if you intend to
post the entry today, and `draft` if you think you're going to work on it for
a couple of days.

`make entry` symlinks the entry from `.draft` in the blog directory, so that
you can edit it and post it without ever having to type the full form of the
filename.

In both cases, the entry or draft is created by copying the contents of the
`TEMPLATE` variable into it, and immediately _committed_ in `git`.  This
commit gives you a permanent record of when you started writing the entry.
Another commit is made when you get around to posting it.  It would be easy to
track things like your average time to write an entry; this is left as an
exercise for the reader.  `TEMPLATE` can be overridden by a definition in
`.config.make`.

Posting an entry is done using `$(POSTCMD)`.  It should be prepared to take an
HTML fragment with an email-style header, so it's usually a wrapper around
whatever program actually makes the post.  Before committing the post, a
`Posted:` header is written into it.  Of course, if you're working directly in
the blog website you can just use `POSTCMD=true`, which makes it a no-op.
That also works for private blogs.

### Jekyll:

Jekyll blogs work a little differently:

* drafts are in `_drafts`, and posts are in `_posts`.
* the front-matter is in YAML format, with `title:` and `tags` fields instead
  of `Subject` and `Tags`.
* The date prefix is `yyyy-mm-dd-` instead of `yyyy/mm/dd--`.
* Posts are markdown rather than HTML.
* entries are posted by copying them into the `_posts` directory; no command
  is needed.

You can get the entire package of Jekyll options by using `jekyll.make`
instead of `entry.make`; they haven't been properly integrated into
`entry.make` yet.

### Other Blogging Systems:



TODO items are in `../to.do`.
