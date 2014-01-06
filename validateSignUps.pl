#!/usr/bin/perl -w
# validateSignUps.pl --- Validates that the signups are correct
# Author: Jay Runkel <jayrunkel@runkelmac.home>
# Created: 21 Dec 2013
# Version: 0.01

use warnings;
use strict;

use MongoDB;
use sessions;
use Data::Dumper;


# Loop through all the gymnasts. For each sign up verify that they:
#  - have signed up for the right number of spots
#  - haven't signed up for any sessions that in which their child is competing

#Questions
# - what are the items that don't count

my $client = MongoDB::MongoClient->new(host => 'localhost:27017');
my $db = $client->get_database( 'readySetGo' );
my $suCol = $db->get_collection( 'signUps' );
my $suLogCol = $db->get_collection( 'signUpLog' );

my $resCursor;
my $aggResult;


sub printNames($$) {
    
    my $cursor = shift;
    my $fieldsArrRef = shift;

    my $count = 1;
    print "First Last ";
    foreach my $field (@$fieldsArrRef) {print "$field ";}
    print "\n";
    
    while ( my $doc = $cursor->next()) {
        print "$count: $doc->{'sib1First'} $doc->{'last'} ";
        foreach my $field (@$fieldsArrRef) {
            print "$doc->{$field} ";
        }
        print "\n";
        $count++;
        
    }
}

sub printSessions($) {
    my $cursor = shift;
    
    my $fieldsArrRef = ['location', 'dateTime', 'item'];
    
    my $count = 1;
    foreach my $field (@$fieldsArrRef) {print "$field ";}
    print "\n";
    
    while ( my $doc = $cursor->next()) {
        print "$count: ";
        foreach my $field (@$fieldsArrRef) {
            print "$doc->{$field} ";
        }
        print "\n";
        $count++;
    }
    
}

sub printFields($$) {
    my $arrayRef = shift;
    my $fieldsRef = shift;

    my $field;
    
    foreach $field (@$fieldsRef) {
        print "$field ";
    }
    print "\n";
    
    foreach my $result (@$arrayRef) {

        foreach $field (@$fieldsRef) {
            print "$result->{$field} ";
        }
        print "\n";
    }
}


print "______________________________________________________\n";
print "Session List\n";
$aggResult = $suLogCol->aggregate([{'$group' => {'_id' => '$item',
                                                'count' => {'$sum' => 1},
                                               }},
                        {"\$project" =>  {
                                           'type' => {"\$cond" => [{"\$or" => generateSetTest($nonMeetSpecificJobs, "\$_id")},
                                                                   'Non-Meet-Specific',
                                                                   'Other']},
                                           'count' => 1,
                                           'job' => '$_id',
                                           '_id' => 0
                        }}
                    ]);

printFields($aggResult, ["job", "type", "count"]);


print "______________________________________________________\n";
print "Gymnasts with fewer than the required sign ups\n";
$resCursor = $suCol->find({'$where' => '(this.competing == 1) && (this.reqNumSignUps > this.signUpCount)'});
printNames($resCursor, ["reqNumSignUps", "signUpCount", "email1", "email2"]);

print "\n";
print "______________________________________________________\n";
print "Gymnasts signed up for the session in which they are competing\n";
$resCursor = $suCol->find({'$where' => 'function levelMatch() {
    var level = this.level;

    var signUpLevels = [];
    var i;
    var retVal = false;
    
    if ("signUp" in this && this.competing == 1) {
        for (i = 0; i < this.signUp.length; i++)
            {
                if (this.signUp[i].item != "Medical Person") {
                   signUpLevels = signUpLevels.concat(this.signUp[i].sessionInfo.levels);
                }
            }
            
            retVal = signUpLevels.indexOf(level) > -1;
        }
 
    return retVal;
}'});
printNames($resCursor, []);


print "______________________________________________________\n";
print "Gymnasts with parents signed up for jobs, but the gymnast is not competing\n";
# $nin => [] probably will not work when there are multiple sign ups
$resCursor = $suCol->find({"competing" => 0, "signUpCount" => {'$gt' => 0}, "signUp.item" => {'$nin' => $noReportJobs}});
printNames($resCursor, ["signUpCount", "email1", "email2"]);


print "\n";
print "______________________________________________________\n";
print "Sessions without sign ups (excluding Runners and 50/50 Raffle)\n";
              
$resCursor = $suLogCol->find({"email" => "", item => {'$nin' => $noReportJobs}})->sort({"sessionInfo.session" => 1});
printSessions($resCursor);
              
    

__END__

=head1 NAME

validateSignUps.pl - Describe the usage of script briefly

=head1 SYNOPSIS

validateSignUps.pl [options] args

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for validateSignUps.pl, 

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
