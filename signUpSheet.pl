#!/usr/bin/perl -w
# signUpSheet.pl --- Generates a .csv file that can be used to create the sign up sheets
# Author: Jay Runkel <jayrunkel@runkelmac.home>
# Created: 22 Dec 2013
# Version: 0.01

use warnings;
use strict;
use experimental 'smartmatch';

use Scalar::Util qw(looks_like_number);
use MongoDB;
use Data::Dumper;
use DateTime;
use DateTime::Format::Strptime;
use sessions;


my $dbName = $ARGV[0] or die "First argument is the database name\n";

my $client = MongoDB::MongoClient->new(host => 'localhost:27017');
my $db = $client->get_database( $dbName );
my $suCol = $db->get_collection( 'signUps' );
my $suLogCol = $db->get_collection( 'signUpLog' );

my $strp = DateTime::Format::Strptime->new(
    pattern   => '%m/%d/%y %I:%M%p',
    locale    => 'en_US',
    time_zone => 0
);


sub formatDateTime($) {
    my $dateTime = shift;

    return $strp->format_datetime($dateTime);
}


sub getSessionEmptySignups($$$$) {
    my $session = shift;
    my $itemField = shift;
    my $itemFilter = shift;
    my $jobListRef = shift;

    my $results = [];
        
    $session = looks_like_number($session) ? $session + 0 : $session;
    my $cursor = $suLogCol->find({"email" => "", "sessionInfo.session" => $session, "item" => {$itemFilter => $jobListRef}});

    while (my $su = $cursor->next()) {
        $su->{$itemField} = $su->{'item'};
	$su->{'first'} = $su->{'firstName'};
	$su->{'last'} = $su->{'lastName'};

        push(@$results, $su);
    }

    return($results);
}

# \$or" => [{"\$eq" => ["\$signUp.item", "Admissions"]}, 
#                                                                  {"\$eq" => ["\$signUp.item", "Concessions"]},
#                                                                  {"\$eq" => ["\$signUp.item", "Gymnasts Sign-in/Front Bathroom"]},
#                                                                  {"\$eq" => ["\$signUp.item", "Parking Lot Attendant"]},
#                                                                  {"\$eq" => ["\$signUp.item", "Souveniers"]},
#                                                                  {"\$eq" => ["\$signUp.item", "Announcer/Door Monitor/Back Bathroom"]},
#                                                                  {"\$eq" => ["\$signUp.item", "Medical Person"]}
#                                                                 ]

my $result = $suCol->aggregate(
    [
        {"\$match" => {"signUp" => {"\$exists" => 1}}},
        {"\$unwind" => "\$signUp"},
        {"\$group" => {
            "_id" => "\$signUp.sessionInfo.session",
            "jobs" => {"\$push" => {"\$cond" => [{"\$or" => generateSetTest($nonMeetSpecificJobs, "\$signUp.item")},
                                                     {"prepJob" => "\$signUp.item",
                                                      "first" => "\$signUp.firstName",
                                                      "last" => "\$signUp.lastName",
                                                      "dateTime" => "\$signUp.dateTime", 
                                                      "reqNumSignUps" => "\$reqNumSignUps",
                                                      "signUpCount" => "\$signUpCount"},
                                                     {"sessionJob" => "\$signUp.item",
                                                      "first" => "\$signUp.firstName",
                                                      "last" => "\$signUp.lastName",
                                                      "dateTime" => "\$signUp.dateTime",
                                                      "reqNumSignUps" => "\$reqNumSignUps",
                                                      "signUpCount" => "\$signUpCount"}
                                                 ]}} 
     }},
     {"\$sort" => {"_id" => 1}}
 ]
);  

#print Dumper($result);

my $signInData = {};
my @sessions = ();
my $sessSignInData;
my $sessionId;
my $sessionJob;
my @sortedJobs;
my $jobModifier;


foreach my $sessJob (@$result) {
    
    $sessionId = $sessJob->{'_id'};
    $sessionId =~ s/([\w']+)/\u\L$1/g; # make session names as title case
#    print "setting up session: $sessionId\n";
    
    push(@sessions, $sessionId);
    
    $sessSignInData = {
        sessionId => $sessionId, #sessJob->{'_id'},
        sessionJobs => [],
        prepJobs => []
    };
    
#    print "Session: $sessJob->{'_id'}\n";
#    print Dumper($sessJob->{'jobs'});

    foreach my $job (@{$sessJob->{'jobs'}}) {
            
        if (defined($job->{'sessionJob'})) {
#            print "pushing session job: \n";
#            print Dumper($job);
            
            push(@{$sessSignInData->{'sessionJobs'}}, $job)
        }
        else {
            push(@{$sessSignInData->{'prepJobs'}}, $job)
        }
    }
#    print "Session $sessionId done\n";
#    print Dumper($sessSignInData);
    
    $signInData->{$sessionId} = $sessSignInData;            
}

# Print out session jobs
foreach my $s (@sessions) {
    if (!($s ~~ @setUpSessions) && $signInData->{$s}->{'sessionJobs'}->[0]->{'dateTime'}) {
        print "SESSION $s: @{[formatDateTime($signInData->{$s}->{'sessionJobs'}->[0]->{'dateTime'})]},,,\n";
        print "Job:,Name:,Check-in Signature,Event:\n";

        @sortedJobs = sort {$a->{'sessionJob'} cmp $b->{'sessionJob'}} (@{$signInData->{$s}->{'sessionJobs'}}, @{getSessionEmptySignups($s, 'sessionJob', '$nin', $allNonSessionJobs)});
        
        foreach my $job (@sortedJobs) {
            if (!($job->{'sessionJob'} ~~ @$noReportJobs)) {
                $jobModifier = $job->{'sessionJob'} eq "Squad Leader" ? 'BM/FL/UB/VT' : "";
                
                if (defined $job->{'last'}) {
                    print "$job->{'sessionJob'},$job->{'first'} $job->{'last'},,$jobModifier\n";
                }
                else {
                    print "$job->{'sessionJob'},,,$jobModifier\n";
                }
            }
        }
        print ",,,\n"; 
    }
}

# Print out session non-meet specific jobs - aka prep jobs
foreach my $s (@sessions) {
    if (!($s ~~ @setUpSessions) && $signInData->{$s}->{'prepJobs'}->[0]->{'dateTime'}) {
        print "SESSION $s (Non-Meet Specific):,,,\n";
        
        print "Date Time,Job:,Name:,Check-in Signature\n";

        @sortedJobs = sort {$a->{'dateTime'} cmp $b->{'dateTime'} || $a->{'prepJob'} cmp $b->{'prepJob'}} (@{$signInData->{$s}->{'prepJobs'}}, @{getSessionEmptySignups($s, 'prepJob', '$in', $nonMeetSpecificJobs)});

        foreach my $job (@sortedJobs) {
            if (defined $job->{'last'}) {
                print "@{[formatDateTime($job->{'dateTime'})]},$job->{'prepJob'},$job->{'first'} $job->{'last'},,\n";
            }
            else {
                print "@{[formatDateTime($job->{'dateTime'})]},$job->{'prepJob'},,,\n";
            }
        }
        print ",,,\n"; 
    }

}

#print "-----------Starting pre and post meet jobs---------\n";




#print out pre and post meet jobs
foreach my $s (@setUpSessions) {
#    print "Session: $s\n";
#    print Dumper($signInData->{$s});
        print "$s: @{[formatDateTime($signInData->{$s}->{'sessionJobs'}->[0]->{'dateTime'})]},,,\n";
        
        print "Job:,Name:,Check-in Signature\n";

        @sortedJobs = sort {$a->{'sessionJob'} cmp $b->{'sessionJob'}} (@{$signInData->{$s}->{'sessionJobs'}}, @{getSessionEmptySignups($s, 'sessionJob', '$nin', $noReportJobs)});
        
        foreach my $job (@sortedJobs) {
            if (defined $job->{'last'}) {
                print "$job->{'sessionJob'},$job->{'first'} $job->{'last'},,\n";
            }
            else {
                print "$job->{'sessionJob'},,,\n";

            }
        }
        print ",,,\n"; 
    }


# Print out gymnast jobs
foreach my $s (@sessions) {
    if (!($s ~~ @setUpSessions) && $signInData->{$s}->{'sessionJobs'}->[0]->{'dateTime'}) {
        print "SESSION $s (Gymnast): @{[formatDateTime($signInData->{$s}->{'sessionJobs'}->[0]->{'dateTime'})]},,,\n";
        print "Job:,Name:,Check-in Signature,Event:\n";

        @sortedJobs = sort {$a->{'sessionJob'} cmp $b->{'sessionJob'}} (@{$signInData->{$s}->{'sessionJobs'}}, @{getSessionEmptySignups($s, 'sessionJob', '$in', $noReportJobs)});

#	print "Empty Jobs\n";
#	print Dumper(@{getSessionEmptySignups($s, 'sessionJob', '$in', $noReportJobs)});
        
        foreach my $job (@sortedJobs) {
            if ($job->{'sessionJob'} ~~ @$noReportJobs) {
                $jobModifier = $job->{'sessionJob'} eq "Runners" ? 'BM/FL/UB/VT' : "";
                if (defined $job->{'last'}) {
                    print "$job->{'sessionJob'},$job->{'first'} $job->{'last'},,$jobModifier\n";
                }
                else {
                    print "$job->{'sessionJob'},,,$jobModifier\n";
                }
            }
        }
        print ",,,\n"; 
    }
}


#print Dumper($signInData);



__END__

=head1 NAME

signUpSheet.pl - Describe the usage of script briefly

=head1 SYNOPSIS

signUpSheet.pl [options] args

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for signUpSheet.pl, 

=head1 AUTHOR

Jay Runkel, E<lt>jayrunkel@runkelmac.homeE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Jay Runkel

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
