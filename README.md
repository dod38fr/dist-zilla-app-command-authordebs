# dist-zilla-app-command-installauthordebs

A Dist::Zilla command to list or install author dependencies with
Debian perl packages.

This command is useful to work on the source of a Perl module that uses Dist::Zilla.

To install the author dependencies (i,e, all the `Dist::Zilla` plugins
and extensions) required to build a module, run either:

 $ dzil authordebs --install  # require sudo to allow apt-get install

 $ sudo apt-get install $(dzil authordebs)

The former command is preferred as only `apt-get` command is run as root.

# Installation

On Debian (soon) and derivatives:

 apt install libdist-zilla-app-command-installauthordebs-perl




