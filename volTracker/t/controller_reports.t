use strict;
use warnings;
use Test::More;


use Catalyst::Test 'volTracker';
use volTracker::Controller::reports;

ok( request('/reports')->is_success, 'Request should succeed' );
done_testing();
