use warnings;
use strict;

use File::Slurp;

my $fileName = $ARGV[0] or die "First argument is the path to the competitors file in CSV format\n";

open(my $fh, '<', $fileName) or die "Could not open '$fileName' $!\n";

my $doc = read_file($fileName);

$doc =~ s/Nevaeh/Navaeh/s;
$doc =~ s/Wesztergom/Westergrom/s;
$doc =~ s/O'Brien/OBrien/s;
$doc =~ s/Addyson/Addy/s;
$doc =~ s/Allesandra/Allie/s;
$doc =~ s/Delaney/Delany/s;
$doc =~ s/Margaret/Maggie/s;
$doc =~ s/VonAbo/Von Abo/sg;
    
print $doc;    
