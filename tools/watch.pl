use File::Monitor;
use Data::Dump qw/dump/;

$\ = "\n"; $, = "\t";

my $monitor = File::Monitor->new();

$monitor->watch({ name     => 'templates',
		  recurse  => 1,
		  callback => {
			       change => sub {
				   my ($name, $event, $change) = @_;
				   print $name, $event, $change;
			       }
			      }
		});
while (1) {
    $monitor->scan;
    sleep 3;
}
