#!/usr/bin/perl -w
# sessions.pm --- Defines the global variables used by the application
# Author: Jay Runkel <jayrunkel@runkelmac.home>
# Created: 02 Jan 2014
# Version: 0.01

package sessions;


use warnings;
use strict;
use Exporter;

our @ISA = 'Exporter';
our @EXPORT = qw(@setUpSessions $noReportJobs $nonMeetSpecificJobs $allNonSessionJobs generateSetTest);


our @setUpSessions = ('Pre-meet', 'Post-meet');  
our $noReportJobs = ['Runners', '50/50 Raffle'];  #gymnast jobs
our $nonMeetSpecificJobs = ['Admissions', 'Concessions', 'Gymnast Sign-in/Front Bathroom', 'Parking Lot Attendant', 'Souveniers', 'Crowd Control', 'Concession Runner'];
our $allNonSessionJobs = \(@$noReportJobs, @$nonMeetSpecificJobs );

sub generateSetTest($$) {
    my $arrayRef = shift;
    my $compStr = shift;

    my @eqArray = ();
    
    foreach my $val (@$arrayRef ) {
        my $eqHash = {"\$eq" => [$compStr, $val]}; 
        push(@eqArray, $eqHash);
    }

    return \@eqArray;
}


__END__

=head1 NAME

sessions.pl - Describe the usage of script briefly

=head1 SYNOPSIS

sessions.pl [options] args

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for sessions.pl, 

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
