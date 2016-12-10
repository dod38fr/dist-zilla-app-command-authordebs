use strict;
use warnings;
use 5.010;
package Dist::Zilla::App::Command::authordebs;

use Debian::AptContents;
use DhMakePerl::Utils qw(is_core_module);
use Dist::Zilla::Util::AuthorDeps;

use Dist::Zilla::App -command;

sub abstract { "list or install authordeps using Debian packages" }

sub opt_spec
{
    [ 'install'   , 'also run sudo apt-get install for missing packages' ],
}

sub execute
{
    my ($self, $opt) = @_; # $arg

    $self->app->chrome->logger->mute unless $self->app->global_options->verbose;

    my $apt_contents = Debian::AptContents->new( { homedir => $ENV{'HOME'}.'/.dh-make-perl' } );

    unless ($apt_contents) {
        die <<EOF;
Unable to locate module packages, because APT Contents files
are not available on the system.

Please install the 'apt-file' package, run 'sudo apt-file update' as root
and retry.
EOF
    }

    my $dep_list = Dist::Zilla::Util::AuthorDeps::extract_author_deps('.',1);

    if (not @$dep_list ) {
        warn "All dzil dependencies are already available\n";
        exit;
    }

    my @pkgs;
    foreach my $dep (@$dep_list) {
        my ($mod, $version) = %$dep;
        if ( my $pkg = $apt_contents->find_perl_module_package($mod) ) {
            warn "$mod is in $pkg package\n";
            push @pkgs , $pkg;
        }
        else {
            warn "$mod is not found in any Debian package\n";
        }
    }

    if ($opt->{install} and @pkgs) {
        warn "Installing required packages...\n";
        system(qw/sudo apt-get install/,@pkgs);
    }
    else {
        say join("\n",@pkgs);
    }
}


1;

__END__

=head1 NAME

dpt-install-dzil-deps -- Install Dist::Zilla authors dependencies

=head1 SYNOPSIS

C<dpt install-dzil-deps>

=head1 DESCRIPTION

B<dpt install-dzil-deps> uses L<Dist::Zilla::Util::AuthorDeps> to scan
the Perl module required to build a Perl module using L<Dist::Zilla> and install
them as Debian package.

Note: the installation is done with C<sudo apt-get install>, so you
must have sudo configured properly.

=head1 COPYRIGHT & LICENSE

Copyright (C) 2016 Dominique Dumont <dod@debian.org>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut

1;
