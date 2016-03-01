# How to Contribute

This project is [MIT licensed](LICENSE) and accepts contributions via
GitHub pull requests.  This document outlines some of the conventions on
development workflow, commit message formatting, contact points and other
resources to make it easier to get your contribution accepted.

# Certificate of Origin

By contributing to this project you agree to the Developer Certificate of
Origin (DCO). This document was created by the Linux Kernel community and is a
simple statement that you, as a contributor, have the legal right to make the
contribution. See the [DCO](DCO) file for details.

## Getting Started

- Fork the repository on GitHub
- Play with the project, submit bugs, submit patches

## Contribution Flow

This is a rough outline of what a contributor's workflow looks like:

- Create an issue branch from where you want to base your work (usually `dev`).
- Make commits of logical units, the smaller, the better.
- Make sure your commit messages are in the proper format (see below).
- Push your changes to an issue branch in your fork of the repository.
- Submit a pull request to the original repository.

Thanks for your contributions!

### Coding Style

Please avoid horizontal scrolling and limit yourself to a line length of 
around 80 characters. It's also nice to have not more than one statement 
per line. That makes reading code or temporarily uncommenting a line much 
easier.

### Format of the Commit Message

We follow a rough convention for commit messages that is designed to answer two
questions: what changed and why. The _subject line_ should feature the "what" and
the _body_ of the commit should describe the "why".

```
fix(volume) Fix missing config volume, see #123
           it's easier to put the issue here ^

Add a new volume to allow users to mount their custom Nginx config
and therefore reuse it in as many containers as they want.

Fixes #123
    ^ this is optional
```

The format can be described more formally as follows:

```
<type>(<sub-part>) <what changed>, see <issue #>
<BLANK LINE>
<why this change was made>
<BLANK LINE>
<footer>
```

The first line is the subject and should be no longer than 70 characters, the
second line is always blank, and other lines should be wrapped at 80 characters.
This allows the message to be easier to read on GitHub as well as in various
git tools.