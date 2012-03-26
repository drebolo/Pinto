package Pinto::Action::Mirror;

# ABSTRACT: Pull all the latest distributions into your repository

use Moose;

use URI;
use Try::Tiny;

use Pinto::Util;
use Pinto::Types qw(StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------
# Moose Attributes

has stack => (
    is      => 'ro',
    isa     => StackName,
    default => 'default',
);


# has force => (
#    is      => 'ro',
#    isa     => Bool,
#    default => 0,
# );

#------------------------------------------------------------------------------
# Moose Roles

with qw(Pinto::Role::FileFetcher);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    # For speed, we're going to just make a hash table of all the dist
    # paths in the database.  Then we'll use the hash to decide which
    # dists we need to import and which ones we already have.  This is
    # a lot faster than querying the database for each and every path.
    my $attrs = {select => 'path'};
    my $rs    = $self->repos->select_distributions(undef, $attrs);
    my %seen  = map { $_ => 1 } $rs->all();


    my $count = 0;
    for my $struct ( $self->repos->cache->contents() ) {

        my $path = $struct->{path};
        if ( Pinto::Util::isa_perl($path) ) {
            $self->debug("Distribution $path is a perl.  Skipping it.");
            next;
        }

        if ($seen{$path}) {
            $self->debug("Already have distribution $path.  Skipping it.");
            next;
        }

        $count += try   { $self->_do_mirror($struct)      }
                  catch { $self->_handle_mirror_error($_) };

    }

    return 0 if not $count;

    $self->add_message("Mirrored $count distributions");

    return 1;
}

#------------------------------------------------------------------------------

sub _do_mirror {
  my ($self, $struct) = @_;

  my $dist = $self->repos->mirror_distribution( struct => $struct,
                                                stack  => $self->stack() );

  return 1;
}

#------------------------------------------------------------------------------

sub _handle_mirror_error {
    my ($self, $error)  = @_;

    # TODO: Be more selective about which errors we swallow.  Right
    # now, we swallow any error that came from Pinto.  But all others
    # are fatal.

    if ( blessed($error) && $error->isa('Pinto::Exception') ) {
        $self->add_exception($error);
        $self->whine($error);
        return 0;
    }

    $self->fatal($error);

    return;  # should never get here;
}

#------------------------------------------------------------------------------
# ARGH!  A handful of arcane packages on CPAN have broken version
# numbers.  They are probably really old and will never be updated.
# For the sake of completeness, we don't want to exclude them. But
# Pinto requires every package to have a sane version number.  So the
# best we can do is provide a substitute version number.

sub _fix_versions {
    my ($self, $pkg_specs) = @_;

    my @fixed;
    for my $pkg_spec ( @{ $pkg_specs || [] } ) {

        my ($pkg_name, $pkg_ver) = ( $pkg_spec->{name}, $pkg_spec->{version} );

        if ( not eval { version->parse( $pkg_ver ); 1} ) {
            $self->whine("Package $pkg_name-$pkg_ver has invalid version.  Forcing it to 0");
            $pkg_ver = 0;
        }

        push @fixed, { name => $pkg_name, version => $pkg_ver };
    }

    return \@fixed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
