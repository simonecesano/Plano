use Mojolicious;
use Mojo::DOM;
use Path::Tiny;
use Text::MultiMarkdown;


my $d = Text::MultiMarkdown->new();

my $dom = Mojo::DOM->new($d->markdown(path($ARGV[0])->slurp_utf8));

my $m = Mojolicious->new->log(Mojo::Log->new);
my $c = Mojolicious::Controller->new->app($m);
my $r = $m->renderer;

$dom->find('p')->each(sub {
			  my $i = shift;

			  return unless $i->text =~ /\?/;
			  
			  my $text = $i->text;
			  my ($text, $id) = $text =~ /(.+)(#.+)/;
			  my ($text, $caption) = $text =~ /(.+\?)\s*(.+)/;			  

			  $id = $id || $i->text; for ($id) {
			      s/\W+/_/g;
			      s/^_+|_+$//g;
			      $_ = lc $_;
			  }
			  
			  my $n = $i->next;
			  if ($n) {
			      for ($n->tag) {
				  /^(ul|ol)$/ && do {
				      my $list = $n->find('li')->map(sub { shift->all_text });
				      $c->stash({ description => $text, id => $id, list => $list, caption => $caption });
				      my ($output, $format) = $r->render($c, { template => 'radio' });
				      
				      $n->remove;
				      $i->replace(Mojo::DOM->new($output));
				      last;
				  };

				  $c->stash({ description => $text, id => $id, caption => $caption });
				  my ($output, $format) = $r->render($c, { template => 'simple' });
				  $i->replace(Mojo::DOM->new($output));

			      };
			  } else {
			      $c->stash({ description => $text, id => $id });
			      my ($output, $format) = $r->render($c, { template => 'simple' });
			      $i->replace(Mojo::DOM->new($output));
			  }
		      });

$dom = "$dom";

$dom =~ s/\n+/\n/gms;

print $dom;


  
__DATA__
@@ select.html.ep
<div class="form-group">
  <label for="<%= $id %>"><%= $description %></label>
  <select name="<%= $id %>" id="<%= $id %>">
    % for (@$list) {
    % my $o = $_; s/\W+/_/g; $_ = lc $_;
    <option value="<%= $_ %>"><%= $o %></option> 
    % }
  </select>
</div>
@@ simple.html.ep
<div class="form-group">
  <label for="<%= $id %>"><%= $description %></label>
  <input type="text" class="form-control" id="<%= $id %>" name="<%= $id %>">
  % if ($caption =~ /\w/) {
  <small class="form-text text-muted"><%= $caption %></small>
  % }
</div>
@@ radio.html.ep
<div class="form-group">
  <label for="<%= $id %>"><%= $description %></label>
  % my $i = 0; my $class = 'form-check'; my $l = length join '', @$list;
  % if ($l < 96) { $class = join ' ', $class, 'form-check-inline' }
  % if ($l < 96) {
  <br />
  % }
  % for (@$list) {
  % my $o = $_; s/\W+/_/g; s/^_+|_+$//g; $_ = lc $_;
  <div class="<%= $class %>">
      <input class="form-check-input" name="<%= $id %>" type="radio" value="<%= $_ %>" id="<%= $id %>_<%= ++$i %>">
      <label class="form-check-label" for="<%= $id %>_<%= $i %>">
      <%= $o %>
    </label>
    % if ($caption =~ /\w/) {
    <small class="form-text text-muted"><%= $caption %></small>
    % }
  </div>
  % }
</div>
