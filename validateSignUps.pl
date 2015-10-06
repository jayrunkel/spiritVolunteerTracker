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

my $dbName = $ARGV[0] or die "First argument is the database name\n";


my $client = MongoDB::MongoClient->new(host => 'localhost:27017');
my $db = $client->get_database( $dbName );
my $suCol = $db->get_collection( 'signUps' );
my $suLogCol = $db->get_collection( 'signUpLog' );

my $resCursor;
my $aggCursor;
my @aggResult;


sub printNames($$) {
    
    my $cursor = shift;
    my $fieldsArrRef = shift;

    my $lineCount = 1;
    my $count;
    
    print "First Last ";
    foreach my $field (@$fieldsArrRef) {print "$field ";}
    print "\n";
    
    while ( my $doc = $cursor->next()) {
        print "$lineCount: $doc->{'gymnasts'}[0]->{'first'} $doc->{'last'} ";
        foreach my $field (@$fieldsArrRef) {

            my $refType = ref($doc->{$field});

            if ($refType eq "ARRAY") {
                $count = 0;
                foreach my $val (@{$doc->{$field}}) {
                    print "/" if $count > 0;
                    print "$val";
                    $count++;
                }
                print " ";
            }
            else {
                print "$doc->{$field} ";                
            }
        }
        print "\n";
        $lineCount++;
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

sub printConflicts($) {
    my $cursor = shift;
    
    my $count = 1;
    my $conflictCount;
    my $emailCount;
    

    print "First Last Session1 Item1 Parent1 Session2 Item2 Parent2 emails\n";
        
    while ( my $doc = $cursor->next()) {
        print "$count: ";

        print "$doc->{'gymnasts'}->[0]->{'first'} ";
        print "$doc->{'last'} ";
        $conflictCount = 0;
        foreach my $conflict (@{$doc->{'conflicts'}}) {
            print "\n                              " if $conflictCount > 0;
            
            print "$conflict->{'first'}->{'session'} ";
            print "$conflict->{'first'}->{'item'} ";
            print "$conflict->{'first'}->{'firstName'} ";
            print "$conflict->{'second'}->{'session'} ";
            print "$conflict->{'second'}->{'item'} ";
            print "$conflict->{'second'}->{'firstName'} ";

            if ($conflictCount == 0) {
                $emailCount = 0;
                foreach my $email (@{$doc->{'emails'}}) {
                    print "/" if $emailCount > 0;
                    print "$email";
                    $emailCount++;
                }
            }
            
            $conflictCount++;
        }
        
        print "\n";
        $count++;
    }
    
}



sub printFields($$) {
    my $arrayRef = shift;
    my $fieldsRef = shift;

    my $field;
    my $count;
    my $lineCount = 1;
    
    foreach $field (@$fieldsRef) {
        print "$field ";
    }
    print "\n";
    
    foreach my $result (@$arrayRef) {
        print "$lineCount: ";
        
        foreach $field (@$fieldsRef) {
            my $refType = ref($result->{$field});
#            print "The ref type for $result->{$field} is $refType\n";
#            print ">$refType\n";

            
            if ($refType eq "ARRAY" ) {
                $count = 0;
                foreach my $val (@{$result->{$field}}) {
                    print "/" if $count > 0;
                    print "$val";
                    $count++;
                }
                print " ";
            }
            else {
                print "$result->{$field} ";
            }

        }
        print "\n";
        $lineCount++;

    }
}


print "______________________________________________________\n";
print "Session List\n";
$aggCursor = $suLogCol->aggregate([{'$group' => {'_id' => '$item',
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

@aggResult = $aggCursor->all();
printFields(\@aggResult, ["job", "type", "count"]);


print "______________________________________________________\n";
print "Gymnasts with fewer than the required sign ups\n";
#$resCursor = $suCol->find({'$where' => '(this.competing == 1) && (this.reqNumSignUps > this.signUpCount)'});
#printNames($resCursor, ["reqNumSignUps", "signUpCount", "email1", "email2"]);

$aggCursor = $suCol->aggregate([{'$match' =>  {'gymnasts.competing' => 1}},
                                {'$project' => {
                                    'first' => '$gymnasts.first',
                                    'last' => '$last',
                                    'emails' => '$emails',
                                    'reqNumSignUps' => '$reqNumSignUps',
                                    'signUpCount' => '$signUpCount',
                                    'fail' => {'$cond' => [{'$gt' => ['$reqNumSignUps', '$signUpCount']}, 1, 0]}}},
                                {'$match' => {'fail' => 1}}
			       ]);
@aggResult = $aggCursor->all();
printFields(\@aggResult, ["first", "last", "reqNumSignUps", "signUpCount", "emails"]);

print "\n";
print "______________________________________________________\n";
print "Gymnasts with greater than the required sign ups\n";

$aggCursor = $suCol->aggregate([{'$match' =>  {'gymnasts.competing' => 1}},
                                {'$project' => {
                                    'first' => '$gymnasts.first',
                                    'last' => '$last',
                                    'emails' => '$emails',
                                    'reqNumSignUps' => '$reqNumSignUps',
                                    'signUpCount' => '$signUpCount',
                                    'fail' => {'$cond' => [{'$lt' => ['$reqNumSignUps', '$signUpCount']}, 1, 0]}}},
                                {'$match' => {'fail' => 1}}
			       ]);
@aggResult = $aggCursor->all();
#print Dumper(@aggResult);
printFields(\@aggResult, ["first", "last", "reqNumSignUps", "signUpCount", "emails"]);


print "\n";
print "______________________________________________________\n";
print "Gymnasts signed up for the session in which they are competing\n";
# $resCursor = $suCol->find({'$where' => 'function levelMatch() {
#     var level = this.level;

#     var signUpLevels = [];
#     var i;
#     var retVal = false;
    
#     if ("signUp" in this && this.competing == 1) {
#         for (i = 0; i < this.signUp.length; i++)
#             {
#                 if (this.signUp[i].item != "Medical Person") {
#                    signUpLevels = signUpLevels.concat(this.signUp[i].sessionInfo.levels);
#                 }
#             }
            
#             retVal = signUpLevels.indexOf(level) > -1;
#         }
 
#     return retVal;
# }'});
# printNames($resCursor, []);


$aggCursor = $suCol->aggregate([{'$match' => {'numCompeting' => {'$gt' => 0},
                                             'signUpCount' => {'$gt' => 0}}},
                                {'$unwind' => '$gymnasts'},
                                {'$unwind' => '$signUp'},
                                {'$match' => {
                                    '$and'=> [
                                        {'signUp.item' => {'$ne' => 'Medical Person'}},
                                        {'signUp.item' => {'$nin' => $noReportJobs}}
                                    ]
                                }
                                },
                                {'$project' => {
                                    '_id' => '$_id',
                                    'first' => '$gymnasts.first',
                                    'last' => '$last',
                                    'level' => '$gymnasts.level',
                                    'session' => '$gymnasts.session',
                                    'signUpLevels' => '$signUp.sessionInfo.levels',
                                    'signUpSession' => '$signUp.sessionInfo.session',
                                    'signUpFirst' => '$signUp.firstName',
                                    'signUpItem' => '$signUp.item'
                                }},
#                                {'$unwind' => '$signUpLevels'},
                                {'$project' => {
                                    '_id' => '$_id',
                                    'first' => '$first',
                                    'last' => '$last',
                                    'level' => '$level',
                                    'signUpLevels' => '$signUpLevels',
                                    'signUpSession' => '$signUpSession',
                                    'signUpFirst' => '$signUpFirst',
                                    'signUpItem' => '$signUpItem',
                                    'session' => '$session',
                                    'bad' => {'$cond' => [{'$eq' => ['$session', '$signUpSession']}, 1, 0]}
                                }},
                                {'$match' => {'bad' => 1}}
			       ]);
@aggResult = $aggCursor->all();
#printFields($aggResult, ["first", "last", "level", "signUpLevels", "signUpSession", "signUpFirst", "signUpItem"]);
printFields(\@aggResult, ["first", "last", "level", "session", "signUpSession", "signUpFirst", "signUpItem"]);



print "______________________________________________________\n";
print "Gymnasts with parents signed up for jobs, but the gymnast is not competing\n";
# $nin => [] probably will not work when there are multiple sign ups
$resCursor = $suCol->find({"numCompeting" => 0, "signUpCount" => {'$gt' => 0}, "signUp.item" => {'$nin' => $noReportJobs}});
printNames($resCursor, ["signUpCount", "emails"]);


print "\n";
print "______________________________________________________\n";
print "Sessions without sign ups (excluding Runners and 50/50 Raffle)\n";
              
$resCursor = $suLogCol->find({"email" => "", item => {'$nin' => $noReportJobs}})->sort({"sessionInfo.session" => 1});
printSessions($resCursor);
              

print "\n";
print "______________________________________________________\n";
print "Gymnasts with overlapping sessions (excluding Runners and 50/50 Raffle)\n";
$resCursor = $suCol->find({'conflicts' => {'$exists' => 1}});
printConflicts($resCursor);


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
