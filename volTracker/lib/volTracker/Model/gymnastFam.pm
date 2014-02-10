package volTracker::Model::gymnastFam;

use Moose;
BEGIN { extends 'Catalyst::Model::MongoDB' };

__PACKAGE__->config(
	host => 'localhost',
	port => '27017',
	dbname => 'dalmation2014',
	collectionname => 'signUps',
	gridfs => '',
);

=head1 NAME

volTracker::Model::gymnastFam - MongoDB Catalyst model component

=head1 SYNOPSIS

See L<volTracker>.

=head1 DESCRIPTION

MongoDB Catalyst model component.

=head1 AUTHOR

Jay Runkel

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

1;