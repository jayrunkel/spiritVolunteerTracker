#!/usr/bin/perl -w
# counts.pl --- counts the number of volunteer people and volunteer openings and compares them
# Author: Jay Runkel <jayrunkel@runkelmac.home>
# Created: 11 Jan 2014
# Version: 0.01

use warnings;
use strict;

use MongoDB;
use sessions;
use Data::Dumper;

my $dbName = $ARGV[0] or die "First argument is the database name\n";

my $client = MongoDB::MongoClient->new(host => 'localhost:27017');
my $db = $client->get_database( $dbName );
my $suCol = $db->get_collection( 'signUps' );
my $suLogCol = $db->get_collection( 'signUpLog' );


my $totalFamCompeting = $suCol->count({'numCompeting' => {'$gt' => 0}});
my $totalFamVols = $suCol->count({'numCompeting' => {'$gt' => 0}, 'reqNumSignUps' => {'$gt' => 0}});

my $aggResult = $suCol->aggregate([{'$match' => {'gymnasts.competing' => 1 }},
                                   {'$group' => {'_id' => undef,
                                                 'totalSlots' => {'$sum' => '$reqNumSignUps'}}}]);
my $totalVols = $aggResult->[0]->{'totalSlots'};

my $totalMeetPos = $suLogCol->count({'item' => {'$nin' => $noReportJobs}});

print "\n";
print "________________________________________________________________\n";
print "Total families with gymnasts competing: $totalFamCompeting\n";
print "Total families with gymnasts competing that must volunteer: $totalFamVols\n";
print "Total number of required volunteer positions to be taken by these families: $totalVols\n";
print "Total number of volunteer positions that need to be filled: $totalMeetPos\n";



__END__

=head1 NAME

counts.pl - Describe the usage of script briefly

=head1 SYNOPSIS

counts.pl [options] args

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for counts.pl, 

=head1 AUTHOR

Jay Runkel, E<lt>jayrunkel@runkelmac.homeE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Jay Runkel

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
