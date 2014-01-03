#!/usr/bin/perl -w
# loadSignups.pl --- Load the readySetGo Signups into MongoDB
# Author: Jay Runkel <jayrunkel@RunkelMac.local>
# Created: 25 Sep 2013
# Version: 0.01

use warnings;
use strict;

use Text::CSV_XS;
use DateTime::Tiny;
use MongoDB;

my $dateTimeStrRegEx = '^(\d\d?)/(\d\d?)/(\d\d?)\s(\d\d):(\d\d)\s(AM|PM)$';

sub parseLocation($) {
    my $locStr = shift;

    my $session;
    my @levels = ();
    my $result = {};

    if ($locStr =~ m/^Session\s(\d)+/) {
        $session = $1;

        @levels = split(/\s*[-&\/]\s*/, substr($locStr, index($locStr, 'Level ') + 6));

    }
    else {
        $session = $locStr;
    } ;

    # print "Session Desc: $locStr\n";
    # print "Session: $session\n";
    # print "Levels: @levels\n";

    $result->{'session'} = $session;
    $result->{'levels'} = \@levels;

    return $result;
}

sub parseTime($) {
    my $dateTimeStr = shift;

    $dateTimeStr =~ /$dateTimeStrRegEx/;
    my $hour;

    if (($6 eq 'AM') && ($4 == 12)) {
        $hour = 0;
    }
    elsif (($6 eq 'PM') && ($4 != 12)) {
        $hour = $4 + 12;
    }
    else {
        $hour = $4 + 0;
    }

    my $result = DateTime::Tiny->new(
        year   => $3 + 2000,
        month  => $1 + 0,
        day    => $2 + 0,
        hour   => $hour,
        minute => $5 + 0,
        second => 0);

#    print "Parsed string: $dateTimeStr to @{[$result->DateTime()->mdy()]}\n";
    
    return $result;
}



my $client = MongoDB::MongoClient->new(host => 'localhost:27017');
my $db = $client->get_database( 'readySetGo' );
my $suCol = $db->get_collection( 'signUps' );
my $suLogCol = $db->get_collection( 'signUpLog' );

$suLogCol->drop();


my $csv = Text::CSV_XS->new({ sep_char => ',', binary => 1});

my $file = $ARGV[0] or die "Need to get CSV file on the command line\n";

my $email;
my $gymnast;
my $quantity;         #the number of jobs the user gets credit for, i.e., Runners and 50/50 raffle don't count towards a users requirement
my $signUpQuantity;   #the number of jobs the user has signed up for using sign up genius
my $suLogId;


print "Opening file: $file\n";

open(my $fh, '<', $file) or die "Could not open '$file' $!\n";
my $firstLine = <$fh>;
#print "The first line: $firstLine\n";

while (my $row = $csv->getline($fh)) {
    my $date = $row->[0];
#    print "Date: $date\n";

    $gymnast = undef;
    $email = undef;
    $quantity = 0;

    $signUpQuantity = $row->[2] + 0;



    
    my $record = {
        dateTime => parseTime($row->[0]),
    	location => $row->[1],
        sessionInfo => parseLocation($row->[1]),
#    	quantity => $row->[2],
    	item => $row->[3],
    	firstName => $row->[4],
    	lastName => $row->[5],
    	email => lc($row->[6]),
    	signUpComment => $row->[7],
    	signUpTimestamp => $row->[8],
        itemComment => $row->[9]
    };
    
    #    $suCol->insert($record);
    $email = $record->{'email'};
    $gymnast = $suCol->find_one({'$or' => [{'email1' => $email}, {'email2' => $email}]});
        

    #    print "Inserting record for $row->[1] $row->[3] $record->{'lastName'}...";

    for (my $i = 0; $i < $signUpQuantity; $i++ ) {
        delete $record->{'logId'};
        $quantity = 1;
        
        $suLogId = $suLogCol->insert($record);
        $record->{'logId'} = $suLogId;

        # Runners and 50/50 Raffle people don't count as signups, so the users signup count does not get incremented
        $quantity = 0 if (($record->{'item'} eq 'Runners') || ($record->{'item'} eq '50/50 Raffle'));


        if (defined($email) && ($email ne '')) {
            if ($gymnast) {
                $suCol->update({'_id' => $gymnast->{'_id'}},
                               {'$push' => {'signUp' => $record},
                                '$inc' => {'signUpCount' => $quantity}});
                #            print "position filled\n";
            } else {
                #            print "position empty\n";
            }
        }
        else {
            #\        print "\n";
        }
    
        if (!defined($gymnast) && defined($email) && ($email ne '')) {
            #        die "No gymnast found for signup: $email\n";
            print ">>>>> No gymnast found for signup: $email\n";
        }

        if ((!defined($email) || $email eq '') && (($record->{'lastName'} || $record->{'firstName'}))) {
            print ">>>>> Sign up with name information but no email found for $record->{'firstName'} $record->{'lastName'}\n";
        }
    }
    
    
#    print "Search email: $email\n";
#    $suCol->update({'email' => {'$in' => [$record->{'email1'}, $record->{'email2'}]}},
#                   {'$set' => { 'gymnast' => $record}});    
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
