use strict;
use warnings;
use 5.010;
package Dist::Zilla::App::Command::authordebs;

use Debian::AptContents;
use DhMakePerl::Utils qw(is_core_module);
use Dist::Zilla::Util::AuthorDeps;
use Config::Model::Dpkg;
use Config::Model qw/cme/;

use Dist::Zilla::App -command;

sub abstract { "list or install authordeps using Debian packages" }

sub opt_spec {
    return (
        [ 'missing', 'list only the missing dependencies' ],
        [ 'install', 'also run sudo apt-get install for missing packages' ],
        [ 'update-control|uc', 'Update debian/control file' ],
        [ 'verbose', 'show more information on dependency modules'],
    );
}

sub execute {
    my ($self, $opt) = @_; # $arg

    $self->app->chrome->logger->mute unless $self->app->global_options->verbose;

    my $apt_contents = Debian::AptContents->new( {
        cache_dir => $ENV{'HOME'}.'/.cache/dzil-authordebs',
        verbose => $opt->{verbose} // 0,
    } );

    unless ($apt_contents) {
        die <<EOF;
Unable to locate module packages, because APT Contents files
are not available on the system.

Please install the 'apt-file' package, run 'sudo apt-file update' as root
and retry.
EOF
    }

    my $show_missing = $opt->{missing};
    my $dep_list = Dist::Zilla::Util::AuthorDeps::extract_author_deps('.',$show_missing);

    if (not @$dep_list ) {
        warn "All dzil dependencies are already available\n";
        exit;
    }

    my %pkgs;
    foreach my $dep (@$dep_list) {
        my ($mod, $version) = %$dep;
        if ( my $pkg = $apt_contents->find_perl_module_package($mod) ) {
            warn "$mod is in $pkg package\n" if $opt->{verbose};
            $pkgs{$pkg} = 1;
        }
        else {
            warn "$mod is not found in any Debian package\n";
        }
    }

    if ($opt->{update_control}) {
        warn "updating control file...";

        # add Debian style dependencies
        for my $p (qw/dh-dist-zilla dh-sequence-dist-zilla/) { $pkgs{$p} = 1;}

        # remove package implied by dh-sequence-dist-zilla
        delete $pkgs{'libdist-zilla-perl'};

        # remove git plugin as it cannot be used in Debian build systems
        delete $pkgs{'libdist-zilla-plugin-git-perl'};

        my $pkgs = join( ",", sort keys %pkgs );
        cme('dpkg-control')->modify("source Build-Depends:.ensure($pkgs)");
    }

    if ($opt->{install} and %pkgs) {
        warn "Installing required packages...\n";
        system(qw/sudo apt-get install/, sort keys %pkgs);
    }
    elsif (not $opt->{update_control}) {
        say join("\n",sort keys %pkgs);
    }
}

1;

__END__

# ABSTRACT: List or install Dist::Zilla authors dependencies as Debian packages


=head1 SYNOPSIS

 dzil authordebs --install

 apt install $( dzil authordebs )

=head1 DESCRIPTION

B<dzil authordebs> uses L<Dist::Zilla::Util::AuthorDeps> to scan
the Perl module required to build a Perl module using L<Dist::Zilla> and list the
corresponding Debian packages.

=head1 OPTIONS

=over

=item --missing

Only the missing modules are listed.

=item --install

Install required packages with C<sudo apt-get install>, so you must
have sudo configured properly.

=item --update-control or --uc

Update the "Build-Depends" field of C<debian/control> file with the
required packages.

=back

=head1 EXIT CODE

This command exits 1 if some required dependencies are not available as Debian packages.

=cut

1;
