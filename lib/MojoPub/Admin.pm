package MojoPub::Admin;
use Mojo::Base 'Mojolicious::Controller';

use MongoDB;
use MongoDB::OID;
use Data::Dumper;

# Standard admin dashboard
sub admin {
	my $self = shift;
	return $self->redirect_to('/') unless $self->session('user');
	my $user = $self->session('user');
	$self->render(user => $user);
}

# Add a new post
sub addpost {
	my $self = shift;
	return $self->redirect_to('/') unless $self->session('user');
	my $user = $self->session('user');
	$self->render(user => $user);
}

# Edit a post
sub editpost {
	my $self = shift;
	return $self->redirect_to('/') unless $self->session('user');
	my $user = $self->session('user');

	my $db    = $self->db;
	my $posts = $db->posts;
	my $id    = MongoDB::OID->new( value => $self->param('id') );

	my $post = $posts->find({ _id => $id }); # find records matching requested url

	if (my $doc = $post->next) {

		$self->render( template => 'admin/editpost',
			meta => {
				title   => $doc->{'meta'}->{'title'},
				content => $doc->{'meta'}->{'content'},
				slug 	=> $doc->{'meta'}->{'slug'},
				author  => $doc->{'meta'}->{'author'},
				ts      => $doc->{'meta'}->{'ts'},
				status  => $doc->{'meta'}->{'status'},
			},
			user => $user,
			message => '',
		);
	} else {
		$self->render_text('bum');
	}

	# $self->render(user => $user, template => 'admin/addpost');
}

# List of live/draft posts
sub posts {
	my $self = shift;
	return $self->redirect_to('/') unless $self->session('user');
	my $user = $self->session('user');

	my $db    = $self->db;
	my $posts = $db->posts;

	# returns current URL
	my $req_url = $self->url_for->path->to_abs_string;
	
	my $post = $posts->find; # find all records in the posts collection
	
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
			status  => $doc->{'meta'}->{'status'},
			_id     => $doc->{'_id'},
		});
	}

	$self->render( user => $user, posts => \@post_list );
}


1;
