use strict;
use warnings;

use volTracker;

my $app = volTracker->apply_default_middlewares(volTracker->psgi_app);
$app;

