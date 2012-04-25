# ABSTRACT: Base class for all Actions

package Pinto::Action;

use Moose;
use MooseX::Types::Moose qw(Bool);

use Pinto::Result;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

#------------------------------------------------------------------------------

has repos => (
    is       => 'ro',
    isa      => 'Pinto::Repository',
    required => 1,
);


has result => (
    is       => 'ro',
    isa      => 'Pinto::Result',
    default  => sub { Pinto::Result->new },
    init_arg => undef,
    lazy     => 1,
);

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
