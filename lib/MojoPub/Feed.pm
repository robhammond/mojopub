package MojoPub::Feed;
use Mojo::Base 'Mojolicious::Controller';

use MongoDB;
use MongoDB::OID;
use Data::Dumper;
use DateTime;

sub rss {
	my $self = shift;

	my $db    = $self->db;
	my $posts = $db->posts;

	my $post = $posts->find({'meta.status' => 'live'})->sort({'meta.published' => -1}); # find all records in the posts collection
	
	# check how many matches we get for the query
	my $num = $post->count;

	# AoH
	my @post_list;

	while (my $doc  = $post->next) {
		push(@post_list, { 
			title   => $doc->{'head'}->{'title'},
			author  => $doc->{'meta'}->{'author'},
			published	=> DateTime->from_epoch( epoch => $doc->{'meta'}->{'published'} ),
			slug    => $doc->{'meta'}->{'slug'},
		});
	}
	
	$self->render(
			posts  => \@post_list,
			num => $num,
			brand => $self->{config}->{brand},
		);
}

1;