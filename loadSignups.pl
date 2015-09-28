#!/usr/bin/perl -w
# loadSignups.pl --- Load the readySetGo Signups into MongoDB
# Author: Jay Runkel <jayrunkel@RunkelMac.local>
# Created: 25 Sep 2013
# Version: 0.01

use warnings;
use strict;
use experimental 'smartmatch';

use Text::CSV_XS;
use DateTime;
#use DateTime::Tiny;
use MongoDB;
use Scalar::Util qw(looks_like_number);
use sessions;


my $dateTimeStrRegEx = '^(\d\d?)/(\d\d?)/(\d\d\d?\d?)\s(\d\d):(\d\d)\s(AM|PM)$';


my $dbName = $ARGV[0] or die "First argument should be the database name\n";
my $file = $ARGV[1] or die "Second argument should be the signup CSV file\n";

my $client = MongoDB::MongoClient->new(host => 'localhost:27017');
#$client->dt_type( 'DateTime' );
my $db = $client->get_database( $dbName );
my $suCol = $db->get_collection( 'signUps' );
my $suLogCol = $db->get_collection( 'signUpLog' );

$suLogCol->drop();


my $csv = Text::CSV_XS->new({ sep_char => ',', binary => 1});



sub parseLocation($) {
    my $locStr = shift;

    my $session;
    my @levels = ();
    my $result = {};

    if ($locStr =~ m/^\s*Session\s(\d+)/) {
        $session = $1;

        @levels = split(/\s*[-&\/]\s*/, substr($locStr, index($locStr, 'Level ') + 6));

    }
    else {
        $session = $locStr;
	$session =~ s/([\w']+)/\u\L$1/g; # make session names as title case
    } ;

#    print "Session Desc: $locStr\n";
#    print "Session: $session\n";
#    print "Levels: @levels\n";

    $result->{'session'} = looks_like_number($session) ? $session + 0 : $session;
    $result->{'levels'} = \@levels;

    return $result;
}

sub parseTime($) {
    my $dateTimeStr = shift;

#    print "Parsing date string: $dateTimeStr\n";
    
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

    my $result = DateTime->new(
        year   => $3 + 2000,
        month  => $1 + 0,
        day    => $2 + 0,
        hour   => $hour,
        minute => $5 + 0,
        second => 0,
        time_zone => 0);

#    print "Parsed string: $dateTimeStr to @{[$result->DateTime()->mdy()]}\n";
    
    return $result;
}

sub getEndTime($) {
    my $signUp = shift;

    my $startTime = $signUp->{'dateTime'};
    my $endTime;


#    print "Finding the end time for Session $signUp->{'sessionInfo'}->{'session'} $signUp->{'item'}: ";
    #{'item' : '50/50 Raffle', 'sessionInfo.session': {'$gt' : 2}},{'_id' : 1, 'item' : 1, 'sessionInfo.session' : 1, 'dateTime' : 1}).sort({'item' : 1, 'dateTime' : 1}).limit(1)
    my $nextCursor = $suLogCol->find({'item' => $signUp->{'item'}, 'sessionInfo.session'=> {'$gt' => $signUp->{'sessionInfo'}->{'session'}}},
                                     {'_id' => 1, 'item' => 1, 'sessionInfo.session' => 1, 'dateTime' => 1})->sort({'item' => 1, 'dateTime' => 1})->limit(1);
    my $nextSignUp = $nextCursor->next();
    my $nextStartTime = defined($nextSignUp) ? $nextSignUp->{'dateTime'} : undef;
    
    if (defined($nextSignUp)) {
        if (($startTime->year() == $nextStartTime->year()) &&
                ($startTime->month() == $nextStartTime->month()) && ($startTime->day() == $nextStartTime->day())) {
            $endTime = $nextSignUp->{'dateTime'};
        }
        else {
            $endTime = DateTime->new(year => $startTime->year(), month => $startTime->month(), 'day' => $startTime->day(), hour => 23, minute => 59, second => 0, time_zone => 0);
        }
    }
    else {
        $endTime = DateTime->new(year => $startTime->year(), month => $startTime->month(), 'day' => $startTime->day(), hour => 23, minute => 59, second => 0, time_zone => 0);
    }

#    print "$endTime\n";
    
    return $endTime;
    
}
    
sub getOverlappingSignUps($$) {
    my $newSignUp = shift;
    my $existingSignUps = shift;

    my @conflicts = ();
    my $conflict;

    foreach my $eSignUp (@$existingSignUps) {
        if (($eSignUp->{'firstName'} eq $newSignUp->{'firstName'}) &&
                !($eSignUp->{'item'} ~~ @$noReportJobs) &&
                !($newSignUp->{'item'} ~~ @$noReportJobs) &&
                ((($newSignUp->{'dateTime'}->epoch() > $eSignUp->{'dateTime'}->epoch()) &&
                    ($newSignUp->{'dateTime'}->epoch() < $eSignUp->{'endTime'}->epoch())) ||
                 (($newSignUp->{'endTime'}->epoch() < $eSignUp->{'endTime'}->epoch()) &&
                      ($newSignUp->{'endTime'}->epoch() > $eSignUp->{'dateTime'}->epoch())))) {
            
            
            $conflict = {'first' => {'_id' => $newSignUp->{'_id'},
                                     'firstName' => $newSignUp->{'firstName'},
                                     'session' => $newSignUp->{'sessionInfo'}->{'session'},
                                     'item' => $newSignUp->{'item'},
                                     'start' => $newSignUp->{'dateTime'},
                                     'end' => $newSignUp->{'endTime'}},
                         'second' => {'_id' => $eSignUp->{'_id'},
                                      'firstName' => $eSignUp->{'firstName'},
                                      'session' => $eSignUp->{'sessionInfo'}->{'session'},
                                      'item' => $eSignUp->{'item'},
                                      'start' => $eSignUp->{'dateTime'},
                                      'end' => $eSignUp->{'endTime'}}};
            push(@conflicts, $conflict);
        }
    }

    return \@conflicts;
}



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
    	firstName => $row->[5],
    	lastName => $row->[6],
    	email => lc($row->[7]),
    	signUpComment => $row->[8],
    	signUpTimestamp => $row->[9],
        itemComment => $row->[4]
    };
    
    #    $suCol->insert($record);
    $email = $record->{'email'};

    for (my $i = 0; $i < $signUpQuantity; $i++ ) {

        $suLogCol->insert($record);

        if ((!defined($email) || $email eq '') && (($record->{'lastName'} || $record->{'firstName'}))) {
            print ">>>>> Sign up with name information but no email found for $record->{'firstName'} $record->{'lastName'}\n";
        }
    }
    
    
#    print "Search email: $email\n";
#    $suCol->update({'email' => {'$in' => [$record->{'email1'}, $record->{'email2'}]}},
#                   {'$set' => { 'gymnast' => $record}});    
}
close $fh;

my $cursor = $suLogCol->find({'endTime' => {'$exists' => 0}});
my $overLappingSignUps;      #array reference
my $endTime;
my $pushUpdate;

while (my $signUp = $cursor->next() ) {

    $endTime = getEndTime($signUp);
    $signUp->{'endTime'} = $endTime;
    $suLogCol->update({'_id' => $signUp->{'_id'}}, {'$set' => {'endTime' => $endTime}});
    
#    print "Processing Session $signUp->{'sessionInfo'}->{'session'} $signUp->{'item'}\n";
    
    $email = $signUp->{'email'};
    $gymnast = $suCol->find_one({'emails' => $email});

    $overLappingSignUps = getOverlappingSignUps($signUp, $gymnast->{'signUp'});
    
    # Runners and 50/50 Raffle people don't count as signups, so the users signup count does not get incremented
    $quantity = 1;
    $quantity = 0 if (($signUp->{'item'} eq 'Runners') || ($signUp->{'item'} eq '50/50 Raffle'));

    if (defined($email) && ($email ne '')) {
        if ($gymnast) {

            $pushUpdate = {'signUp' => $signUp};
            $pushUpdate->{'conflicts'} = {'$each' => $overLappingSignUps} if (scalar(@$overLappingSignUps) > 0);
            
            $suCol->update({'_id' => $gymnast->{'_id'}},
                           {'$push' => $pushUpdate,
                            '$inc' => {'signUpCount' => $quantity}});
                #            print "position filled\n";
            } else {
                #            print "position empty\n";
            }
        }
        else {
            #\        print "\n";
        }
    
    if (!defined($gymnast->{'_id'}) && defined($email) && ($email ne '')) {
        #        die "No gymnast found for signup: $email\n";
        my $first = $signUp->{'firstName'};
        my $last = $signUp->{'lastName'};
        print ">>>>> No gymnast found for signup ($first, $last): $email\n";
    }
}



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
