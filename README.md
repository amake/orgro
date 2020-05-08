# Orgro

An [org-mode](https://orgmode.org/) file viewer for iOS and Android

# What is org-mode?

Imagine a plain-text markup language like Markdown, but married to an
application that is a literate programming environment and life organizer. In
[Emacs](https://www.gnu.org/software/emacs/).

# Why?

I started taking notes in org-mode at work, then found myself wanting to view
them on my tablet in meetings. By default on iOS you can't open an `.org` file
at all, as the OS doesn't even know that it's plain text.

I also wanted to try writing a parser with
[PetitParser](https://github.com/petitparser/dart-petitparser); the result
powers this application and is available as a separate library,
[org_parser](https://github.com/amake/org_parser).

# Features

- Syntax highlighting for most org-mode syntax structures
- Expand and collapse sections, blocks, and drawers
- Reflow text for easy viewing on narrow screens
- Pretty table rendering
- Functional external links and section links
- Visibility cycling
- Search
- Narrowing
- "Reader mode" where extraneous markup is hidden

See the [manual](./assets/orgro-manual.org) for details

# Limitations

Orgro is a viewer. It does not support editing at all.

Many org-mode syntax structures are highlighted but not meaningfully
interpreted.
