[<img src="https://orgro.org/assets/appstore.png" alt="Download on the App Store" height="60">](https://apps.apple.com/us/app/orgro/id1512580074?uo=4) [<img src="https://orgro.org/assets/playstore.png" alt="Get it on Google Play" height="60">](https://play.google.com/store/apps/details?id=com.madlonkay.orgro) [<img src="https://orgro.org/assets/fdroid.png" alt="Get it on F-Droid" height="60">](https://f-droid.org/packages/com.madlonkay.orgro/)

# Orgro

An [Org Mode](https://orgmode.org/) file viewer for iOS and Android

<img width="300" src="https://orgro.org/assets/screenshot/flutter_02.png">

_See https://orgro.org for a demo video_

# What is Org Mode?

Imagine a plain-text markup language like Markdown, but married to an
application that is a literate programming environment and life organizer. In
[Emacs](https://www.gnu.org/software/emacs/).

# Why?

I started taking notes in Org Mode at work, then found myself wanting to view
them on my tablet in meetings. By default on iOS you can't open an `.org` file
at all, as the OS doesn't even know that it's plain text.

Other mobile Org Mode apps are focused on very different things like to-dos or
task management; Orgro is instead first and foremost a *viewer*, letting you see
and search the contents of your org files.

I also wanted to try writing a parser with
[PetitParser](https://github.com/petitparser/dart-petitparser); the result
powers this application and is available as a separate library,
[org_parser](https://github.com/amake/org_parser).

# Features

- Syntax highlighting for most Org Mode syntax structures
- Expand and collapse sections, blocks, and drawers
- Reflow text for easy viewing on narrow screens
- Pretty table rendering
- Functional external links and section links
- Visibility cycling
- Search
- Narrowing
- "Reader mode" where extraneous markup is hidden
- Inline and block LaTeX rendering

See the [manual](./assets/manual/orgro-manual.org) for details.

# Limitations

Orgro is a viewer. It does not support editing at all.

Many Org Mode syntax structures are highlighted but not meaningfully
interpreted.

# FAQ

See [here](https://orgro.org/faq/)

# Get it

Orgro is available on the [App
Store](https://apps.apple.com/us/app/orgro/id1512580074?uo=4), [Google
Play](https://play.google.com/store/apps/details?id=com.madlonkay.orgro), and
[F-Droid](https://f-droid.org/packages/com.madlonkay.orgro/), or you can build
and install from source:

1. Install [Flutter](https://flutter.dev/)
2. Clone this repo
3. Attach your device and do `flutter run` from the repo root

# Support Orgro

If you like this app, please show your support by [sponsoring the
author](https://github.com/sponsors/amake) ❤️
