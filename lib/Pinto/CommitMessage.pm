# ABSTRACT: Utility class for constructing commit messages

package Pinto::CommitMessage;

use Moose;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods (autoclean => 1);

use Term::EditorEdit;

use overload ( q{""} => 'to_string' );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has title => (
    is      => 'ro',
    isa     => Str,
    default => '',
);


has details => (
    is      => 'ro',
    isa     => Str,
    default => '',
);

#------------------------------------------------------------------------------

sub edit {
    my ($self) = @_;

    # Term::EditorEdit only honors VISUAL or EDITOR (in that order),
    # So we locally override one of those with PINTO_EDITOR, if set
    local $ENV{VISUAL} = $ENV{PINTO_EDITOR} if $ENV{PINTO_EDITOR};

    my $message = Term::EditorEdit->edit(document => $self->to_string);
    $message =~ s/^ [#] .* $//gmsx;  # Strip comments

    return $message;
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    my $title   = $self->title;
    my $details = $self->details || 'No details available';

    $details =~ s/^/# /gm;

    return <<"END_MESSAGE";
$title


#------------------------------------------------------------------------------
# Please edit or amend the message above to describe the change.  The first
# line of the message will be used as the title.  Any line that starts with 
# a "#" will be ignored.  To abort the commit, delete the entire message above, 
# save the file, and close the editor. 
#
# Details of the changes to be committed:
#
$details
END_MESSAGE
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
