#!/usr/bin/perl -w
# processSiblings.pl --- Merge the gymnast records for siblings
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


my $client = MongoDB::MongoClient->new(host => 'localhost:27017');
my $db = $client->get_database( 'readySetGo' );
my $suCol = $db->get_collection( 'signUps' );


my $csv = Text::CSV_XS->new({ sep_char => ',', binary => 1});

my $file = $ARGV[0] or die "Need to get CSV file on the command line\n";

my $sibling1;
my $sibling2;
my $sibling1Id;
my $sibling2Id;



print "Opening file: $file\n";

open(my $fh, '<', $file) or die "Could not open '$file' $!\n";
my $firstLine = <$fh>;
#print "The first line: $firstLine\n";

while (my $row = $csv->getline($fh)) {

    $sibling1 = $suCol->find_one({'sib1First' => $row->[0], 'last' => trimName($row->[2])});
    $sibling2 = $suCol->find_one({'sib1First' => $row->[1], 'last' => trimName($row->[2])});

    $sibling1Id = $sibling1->{'_id'};
    $sibling2Id = $sibling2->{'_id'};
    
    die "Could not find records for $row->[0] and $row->[1] $row->[2]" if (!defined($sibling1) || !defined($sibling2));

#    print "Merging records for $row->[0] and $row->[1] $row->[2]\n";

    # print "Sibling 2 last: $sibling2->{'last'}\n";
    # print "Sibling 2 First: $sibling2->{'sib1First'}\n";
    # print "Sibling 1 First: $sibling1->{'sib1First'}\n";
#    print "Sibling 2 ID: $sibling2Id\n";
    
    $suCol->update({"_id" => $sibling1Id}, {'$set' => {'sib2First' => $row->[1]}});
    $suCol->remove({'sib1First' => $row->[1], 'last' => trimName($row->[2])}, {'safe' => 1});


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
