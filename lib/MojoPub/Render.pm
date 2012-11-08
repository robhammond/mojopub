package MojoPub::Render;
use Mojo::Base 'Mojolicious::Controller';

use MongoDB;
use MongoDB::OID;
use Data::Dumper;

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

		$self->render( template => 'example/blogpost',
			meta => {
				title 	=> $doc->{'meta'}->{'title'},
				content  	=> $doc->{'meta'}->{'content'},
				author  => $doc->{'meta'}->{'author'},
				ts    	=> $doc->{'meta'}->{'ts'},
				tags	=> $doc->{'meta'}->{'tags'},
			}
		);
	} else {
		$self->render_text(Dumper($post));
	}
}

sub bloghome {
	my $self = shift;

	my $db    = $self->db;
	my $posts = $db->posts;

	my $post = $posts->find({'meta.status' => 'live'}); # find all records in the posts collection
	
	# check how many matches we get for the query
	my $num = $post->count;

	# AoH
	my @post_list;

	while (my $doc  = $post->next) {
		push(@post_list, { 
			title   => $doc->{'meta'}->{'title'},
			author  => $doc->{'meta'}->{'author'},
			ts    	=> $doc->{'meta'}->{'ts'},
			slug    => $doc->{'meta'}->{'slug'},
		});
	}
	
	$self->render( template => 'example/welcome', 
			message => 'welcome to mojoPub!',
			posts  => \@post_list,
			num => $num,
		);
}


1;
