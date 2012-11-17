package MojoPub::Render;
use Mojo::Base 'Mojolicious::Controller';

use MongoDB;
use MongoDB::OID;
use Data::Dumper;
use DateTime;

sub blogpost {
	my $self = shift;

	my $db    = $self->db;
	my $posts = $db->posts;

	# returns current URL
	my ($req_url) = $self->url_for->path->to_abs_string =~ m{^/(.*)$}; # strip leading slash
	
	my $post = $posts->find({ 'meta.slug' => $req_url }); # find records matching requested url
	
	# check how many matches we get for the query
	my $num = $post->count;

	# if there's a match, render it, else show page not found
	if ($num == 1) {
		my $doc = $post->next;

		# sort out SEO options
		my $robots;
		if ($doc->{'meta'}->{'noindex'} == 0) {
			$robots = 'index,';
		} else {
			$robots = 'noindex,';
		}

		if ($doc->{'meta'}->{'nofollow'} == 0) {
			$robots .= 'follow';
		} else {
			$robots .= 'nofollow';
		}
		$robots = "<meta name='robots' content='$robots'>";

		$self->render( template => 'example/blogpost',
			meta => {
				title 	  => $doc->{'head'}->{'title'},
				content   => $doc->{'body'}->{'content'},
				author    => $doc->{'meta'}->{'author'},
				robots    => $robots,
				published => DateTime->from_epoch( epoch => $doc->{'meta'}->{'published'} ),
				tags	  => $doc->{'meta'}->{'tags'},
			}
		);
	} else {
		# debug
		$self->render_text(Dumper($post));
	}
}

sub bloghome {
	my $self = shift;

	my $db    = $self->db;
	my $posts = $db->posts;

	# find all published posts, reverse sorted by publish date
	my $post = $posts->find({'meta.status' => 'live'})->sort({'meta.published' => -1});
	
	# check how many matches we get for the query
	my $num = $post->count;

	# AoH
	my @post_list;

	while (my $doc  = $post->next) {
		push(@post_list, { 
			title   	=> $doc->{'head'}->{'title'},
			author  	=> $doc->{'meta'}->{'author'},
			published	=> DateTime->from_epoch( epoch => $doc->{'meta'}->{'published'} ),
			slug    	=> $doc->{'meta'}->{'slug'},
		});
	}
	
	$self->render( template => 'example/welcome', 
			message => 'welcome to mojoPub!',
			posts  => \@post_list,
			num => $num,
		);
}

1;