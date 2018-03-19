use Mojolicious;
use Data::Dump qw/dump/;
use Getopt::Long::Descriptive;
use Path::Tiny;
use File::Spec;

# $\ = "\n"; $, = "\t";

my ($opt, $usage) = describe_options
    (
     'my-program %o <some-arg>',
     [ 'templates|t=s', "the path to templates", { default  => 'templates' } ],
     [ 'output_dir|o=s', "output directory", { default  => '.' } ],
     [ 'exclude|x=s', "sub-directories to exclude", { default  => 'layouts,components' } ],
     [],
     [ 'verbose|v',  "print extra stuff"            ],
     [ 'help',       "print usage message and exit", { shortcircuit => 1 } ],
    );

print($usage->text), exit if $opt->help;


my $m = Mojolicious->new->log(Mojo::Log->new);
my $c = Mojolicious::Controller->new->app($m);
my $r = $m->renderer;

my $templates = path($opt->templates)->absolute;
push @{$r->paths}, $templates;

my $output_dir = path($opt->output_dir)->absolute;

my $exclude_re = join '|', map { join '', '^', quotemeta($_), '$' } split ',', $opt->exclude;
# print $exclude_re;

use File::Find;

find(sub {
	 return unless -f;

	 for (File::Spec->splitdir($File::Find::dir)) { return if $_ =~ /$exclude_re/; };

	 my $p = path($File::Find::name);
	 my $out = $p->relative(path($templates)->absolute) =~ s/\.ep$//r;
	 $out = path($output_dir, $out);

	 # if ($p->stat->mtime <= $out->stat->mtime) {
	 #     $c->app->log->info(sprintf "File %s is up-to-date", $out);
	 #     return;
	 # }
	 my $tpl = $p->relative(path($templates)->absolute) =~ s/\.(\w+)\.ep$//r;
	 my ($output, $format) = $r->render($c, { template => $tpl });
	 $out->spew_utf8($output);
	 $c->app->log->info(sprintf "Output %d chars to %s", length $output, $out);
     }, @{$r->paths});
