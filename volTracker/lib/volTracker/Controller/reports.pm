package volTracker::Controller::reports;
use Moose;
use namespace::autoclean;

use lib '../..';
use volTracker::Schema::Report;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

volTracker::Controller::reports - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched volTracker::Controller::reports in reports.');
}


=head2 base
 
Can place common logic to start chained dispatch here
 
=cut
 
sub base :Chained('/') :PathPart('reports') :CaptureArgs(0) {
    my ($self, $c) = @_;
 
    # Store the ResultSet in stash so it's available for other methods
#    $c->stash(resultset => $c->model('DB::Book'));
 
    # Print a message to the debug log
    $c->log->debug('*** INSIDE REPORTS BASE METHOD ***');

    # Load status messages
#    $c->load_status_msgs;
}

=head2 list
 
Fetch all book objects and pass to books/list.tt2 in stash to be displayed
 
=cut
 
sub inComplete :Chained('base') :PathPart('incomplete') :Args(0) {
    # Retrieve the usual Perl OO '$self' for this object. $c is the Catalyst
    # 'Context' that's used to 'glue together' the various components
    # that make up the application
    my ($self, $c) = @_;

    my $reportEng = volTracker::Schema::Report->new('db' => $c->model('gymnastFam')->db('dalmation2014'));

 
#$DB::single=1;

    # Retrieve all of the book records as book model objects and store in the
    # stash where they can be accessed by the TT template
    # $c->stash(books => [$c->model('DB::Book')->all]);
    # But, for now, use this code until we create the model later
#    $c->stash(books => [$c->model('DB::Book')->all]);

    $c->stash(reportEng => $reportEng);
    $c->stash(inComplete => $reportEng->inComplete);

 
    # Set the TT template to use.  You will almost always want to do this
    # in your action methods (action methods respond to user input in
    # your controllers).
    $c->stash(template => 'reports/report.tt');

    $c->stash(colName => [$c->model('gymnastFam')->dbnames]);

}


=encoding utf8

=head1 AUTHOR

Jay Runkel

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
