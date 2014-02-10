package volTracker::Schema::Report;

use strict; 
use warnings;

#use Carp;

use Moose;
use MongoDB;
use Data::Dumper;
use namespace::autoclean;


#use sessions;

has 'db' => (
     is => 'rw',
     isa => 'MongoDB::Database',
);

has 'suLogCol' => (
     is => 'rw',
     isa => 'MongoDB::Collection',
);

has 'suCol' => (
     is => 'rw',
     isa => 'MongoDB::Collection',
);

# ================================================================
# Instance will be defined using the database. The BUILD method will
# define the two collections

sub BUILD {
    my $self = shift;
    
    $self->suLogCol($self->db->get_collection( 'signUpLog' ));
    $self->suCol($self->db->get_collection( 'signUps' ));
};


sub inComplete {
     my $self = shift;

     my $aggResult = $self->suCol->aggregate([{'$match' =>  {'gymnasts.competing' => 1}},
                                              {'$project' => {
                                               'first' => '$gymnasts.first',
                                               'last' => '$last',
                                               'emails' => '$emails',
                                               'reqNumSignUps' => '$reqNumSignUps',
                                               'signUpCount' => '$signUpCount',
                                               'fail' => {'$cond' => [{'$gt' => ['$reqNumSignUps', '$signUpCount']}, 1, 0]}}},
                                              {'$match' => {'fail' => 1}}
       ]);                                          
     
     return $aggResult;
};


1;
__END__

=head1 NAME

volTracker::Schema::Report - Perl extension for blah blah blah

=head1 SYNOPSIS

   use volTracker::Schema::Report;
   blah blah blah

=head1 DESCRIPTION

Stub documentation for volTracker::Schema::Report, 

Blah blah blah.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Jay Runkel, E<lt>jayrunkel@RunkelMac.localE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Jay Runkel

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut

