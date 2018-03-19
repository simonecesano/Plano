#! /usr/bin/perl -w
    eval 'exec /usr/bin/perl -S $0 ${1+"$@"}'
        if 0; #$running_under_some_shell

use strict;
use File::Find ();
use Path::Tiny qw/cwd path/;
use Mojo::UserAgent;
use Getopt::Long::Descriptive;

my ($opt, $usage) = describe_options
    (
     'my-program %o <some-arg>',
     [ 'output_dir|d:s', "output directory" ],

     [],
     [ 'verbose|v',  "print extra stuff"            ],
     [ 'help',       "print usage message and exit", { shortcircuit => 1 } ],
    );


$\ = "\n"; $, = "\t";

use vars qw/*name *dir *prune/;
*name   = *File::Find::name;
*dir    = *File::Find::dir;
*prune  = *File::Find::prune;

sub wanted;

my $ua = Mojo::UserAgent->new;
my $od = $opt->output_dir || cwd;

# Traverse desired filesystems
my $templates = path($ARGV[0] || 'templates');
File::Find::find({wanted => \&wanted}, $templates);

exit;



sub wanted {
    return unless -f;
    return if $name =~ /\/layouts\//;
    return if $name =~ /\/components\//;    

    my $url = path($name)->relative($templates) =~ s/\.html\.ep//r;
    my $out = path($name)->relative($templates) =~ s/\.ep//r;

    print $out;

    $url = 'http://localhost:3000/' . $url;

    my $tx = $ua->get($url);
    $out = path($od, $out);
    print $out->absolute;
    $out->spew_utf8($tx->res->body);
}

