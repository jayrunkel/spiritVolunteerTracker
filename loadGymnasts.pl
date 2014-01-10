#!/usr/bin/perl -w
# loadGymnasts.pl --- Load the gymnasts into MongoDB
# Author: Jay Runkel <jayrunkel@RunkelMac.local>
# Created: 26 Sep 2013
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

sub normalizeEmail($)
{
    my $string = shift;
    
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return lc($string);
}

my $client = MongoDB::MongoClient->new(host => 'localhost:27017');
my $db = $client->get_database( 'readySetGo' );
my $suCol = $db->get_collection( 'signUps' );
$suCol->drop();

my $csv = Text::CSV_XS->new({ sep_char => ',', binary => 1});

my $file = $ARGV[0] or die "Need to get CSV file on the command line\n";
my $reqNumSignUps = $ARGV[1] or die "Need to get required number of sign ups on command line\n";
my $count = 1;


print "Opening file: $file\n";

open(my $fh, '<', $file) or die "Could not open '$file' $!\n";
#my $firstLine = <$fh>;
#print "The first line: $firstLine\n";

while (my $row = $csv->getline($fh)) {
    my $name = $row->[2] . ' ' . $row->[1];

    
    my $record = {
        _id => $count,
        level => $row->[0],
    	last => trimName($row->[1]),
        gymnasts => [{first => trimName($row->[2]),
                      level => $row->[0],
                      competing => 0}],
        numCompeting => 0,
        numGymnasts => 0,
    	sib1First => trimName($row->[2]),
        emails => [ normalizeEmail($row->[5]) ],
    	email1 => normalizeEmail($row->[5]),
    	email2 => normalizeEmail($row->[6]),
    	momDadNames => $row->[7],
    	notes => $row->[8],
        reqNumSignUps => $reqNumSignUps + 0,
        signUpCount => 0,
        competing => 0
    };

    push(@{$record->{'emails'}}, normalizeEmail($row->[6])) if normalizeEmail($row->[6]) ne "";
    $count++;
    
    if (defined($record->{'level'}) && ($record->{'level'} ne 'LEVEL') && ($record->{'level'} ne '') && ($record->{'level'} ne '2013-14')) {
 #       print "Gymnast: $name\n";
#        print "Inserting record...\n";

        #    my $email = $record->{'email1'};
        
        #    print "Search email: $email\n";
        #    $suCol->update({'email' => {'$in' => [$record->{'email1'}, $record->{'email2'}]}},
        #                   {'$set' => { 'gymnast' => $record}});

        $suCol->insert($record);
    }
    
}

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
