package MojoPub::Admin;
use Mojo::Base 'Mojolicious::Controller';

use MongoDB;
use MongoDB::OID;
use Data::Dumper;
use DateTime;

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
				title   => $doc->{'head'}->{'title'},
				content => $doc->{'body'}->{'content'},
				slug 	=> $doc->{'meta'}->{'slug'},
				author  => $doc->{'meta'}->{'author'},
				last_updated  => DateTime->from_epoch( epoch => $doc->{'meta'}->{'last_updated'} ),
				status  => $doc->{'meta'}->{'status'},
			},
			user => $user,
			message => '',
		);
	} else {
		$self->render_text('Error locating post! Please try again');
	}
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
	
	my $post = $posts->find->sort({'meta.last_updated' => -1}); # find all records in the posts collection
	
	# check how many matches we get for the query
	my $num = $post->count;

	# AoH
	my @post_list;

	while (my $doc  = $post->next) {
		push(@post_list, { 
			title   		=> $doc->{'head'}->{'title'},
			author  		=> $doc->{'meta'}->{'author'},
			last_updated	=> DateTime->from_epoch( epoch => $doc->{'meta'}->{'last_updated'} ),
			slug    		=> $doc->{'meta'}->{'slug'},
			status  		=> $doc->{'meta'}->{'status'},
			_id     		=> $doc->{'_id'},
		});
	}

	$self->render( user => $user, posts => \@post_list );
}

# Control global/user settings
sub settings {
	my $self = shift;
	return $self->redirect_to('/') unless $self->session('user');
	my $user = $self->session('user');
	$self->render(user => $user);
}

# Theme editor
sub theme {
	my $self = shift;
	return $self->redirect_to('/') unless $self->session('user');
	my $user = $self->session('user');
	$self->render(user => $user);
}

1;
