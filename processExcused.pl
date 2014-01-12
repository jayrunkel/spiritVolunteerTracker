#!/usr/bin/perl -w
# processExcused.pl --- Set the required number of slots for the excused people to 0
# Author: Jay Runkel <jayrunkel@RunkelMac.local>
# Created: 25 Sep 2013
# Version: 0.01

use warnings;
use strict;

use Text::CSV_XS;
use MongoDB;


sub trimName($)
{
    my $string = shift;
    
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;

    return $string;
    
}

my $dbName = $ARGV[0] or die "First argument is the database name\n";
my $file = $ARGV[1] or die "Need to get CSV file on the command line\n";


my $client = MongoDB::MongoClient->new(host => 'localhost:27017');
my $db = $client->get_database( $dbName );
my $suCol = $db->get_collection( 'signUps' );


my $csv = Text::CSV_XS->new({ sep_char => ',', binary => 1});

my $sibling1;
my $sibling2;
my $sibling1Id;
my $sibling2Id;



print "Opening file: $file\n";

open(my $fh, '<', $file) or die "Could not open '$file' $!\n";
my $firstLine = <$fh>;
#print "The first line: $firstLine\n";

while (my $row = $csv->getline($fh)) {

#    print "Excusing $row->[0] $row->[1]\n";
    
    $suCol->update({'gymnasts.first' => $row->[0], 'last' => trimName($row->[1])},
                   {'$set' => {'reqNumSignUps' => ($row->[2] + 0)}});
};

close $fh;


__END__

=head1 NAME

loadSignups.pl - Describe the usage of script briefly

=head1 SYNOPSIS

loadSignups.pl [options] args

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for loadSignups.pl, 

=head1 AUTHOR

Jay Runkel, E<lt>jayrunkel@RunkelMac.localE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Jay Runkel

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
