[<img src="https://orgro.org/assets/appstore.png" alt="Download on the App Store" height="60">](https://apps.apple.com/us/app/orgro/id1512580074?uo=4) [<img src="https://orgro.org/assets/playstore.png" alt="Get it on Google Play" height="60">](https://play.google.com/store/apps/details?id=com.madlonkay.orgro) [<img src="https://orgro.org/assets/fdroid.png" alt="Get it on F-Droid" height="60">](https://f-droid.org/packages/com.madlonkay.orgro/)

# Orgro

An [Org Mode](https://orgmode.org/) app for iOS and Android

https://github.com/amake/orgro/assets/2172537/a3d841a3-84f3-4c34-9381-c73ab4dc9249

# What is Org Mode?

Imagine a plain-text markup language like Markdown, but married to an
application that is a literate programming environment and life organizer. In
[Emacs](https://www.gnu.org/software/emacs/).

# Why?

I started taking notes in Org Mode at work, then found myself wanting to view
them on my tablet in meetings. By default on iOS you can't open an `.org` file
at all, as the OS doesn't even know that it's plain text.

Other mobile Org Mode apps seem focused on specific use cases like to-dos or
task management; Orgro is instead meant to be a well-rounded and high-fidelity
experience for viewing, navigating, and editing Org documents. (In the 5+ years
since I started Orgro, I've added additional functionality only when it fits
well into the core without compromises.)

I also wanted to try writing a parser with
[PetitParser](https://github.com/petitparser/dart-petitparser); the result
powers this application and is available as a separate library,
[org_parser](https://github.com/amake/org_parser).

# Features

## Display
- Syntax highlighting for all Org Mode syntax structures
- Expand and collapse sections, blocks, and drawers
- Reflow text for easy viewing on narrow screens
- “Reader mode” where extraneous markup is hidden
- Pretty table rendering
- Inline and block LaTeX rendering

## Navigation
- Visibility cycling
- Narrowing
- Functional external links, section links, and relative links to other Org
  files (works well with [Org-roam](https://www.orgroam.com/))
- Search: both plain text and regexp
- [Sparse Tree](https://orgmode.org/manual/Sparse-Trees.html)-style filtering
- Jump to/from footnotes
- Jump to `<<link targets>>`, `<<<radio targets>>>`, and src block code
  references like `(foo)`

## Editing
- Edit entire files or narrowed sections as plain text, with various insertion
  helpers
- Some “structured” editing available
  - Tap to toggle checkboxes
  - Slide sections to cycle TODO states
  - Tap to edit timestamps via date/time picker

## Task management
- Functional checkboxes, with [statistics
  cookies](https://orgmode.org/manual/Breaking-Down-Tasks.html)
- Easy cycling of TODO states
- Notifications for Org Agenda items, including recurring items

## External media
- Display linked images
- Attachment support
- Display [Org Cite](https://orgmode.org/manual/Citations.html) citations

## More
- Capture text and links from other apps via the standard OS share UI, and also
  [`org-protocol://`](https://orgmode.org/manual/Protocols.html) links
- Decrypt/encrypt [Org Crypt](https://orgmode.org/manual/Org-Crypt.html)
  sections (currently symmetric keys only)
- Honor document-local `#+STARTUP:`, `#+TODO:`, `#+LANGUAGE:` directives, and
  some local variables

See the [manual](https://orgro.org/manual) for details.

# Limitations

Many Org Mode syntax structures are highlighted but not meaningfully
interpreted.

# FAQ

See [here](https://orgro.org/faq/)

# Get it

Orgro is available on the
[App Store](https://apps.apple.com/us/app/orgro/id1512580074?uo=4),
[Google Play](https://play.google.com/store/apps/details?id=com.madlonkay.orgro),
and [F-Droid](https://f-droid.org/packages/com.madlonkay.orgro/), or you can
build and install from source:

1. Install [Flutter](https://flutter.dev/)
2. Clone this repo
3. Attach your device and do `flutter run` from the repo root

# Support Orgro

If you like this app, please show your support by [sponsoring the
author](https://github.com/sponsors/amake) ❤️
