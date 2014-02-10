package volTracker::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,

    # Set the location for TT files
    INCLUDE_PATH => [
            volTracker->path_to( 'root', 'src' ),
        ],
    # Set to 1 for detailed timer stats in your HTML as comments
    TIMER              => 0,
    # This is your wrapper template located in the 'root/src'
    WRAPPER => 'wrapper.tt',
);

=head1 NAME

volTracker::View::HTML - TT View for volTracker

=head1 DESCRIPTION

TT View for volTracker.

=head1 SEE ALSO

L<volTracker>

=head1 AUTHOR

Jay Runkel

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
