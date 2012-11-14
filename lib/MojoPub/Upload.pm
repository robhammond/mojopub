package MojoPub::Upload;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Upload;

use MongoDB;
use MongoDB::OID;
use Data::Dumper;
use DateTime;
use File::Path qw(make_path);
use Mojo::Log;

my $log = Mojo::Log->new();

# Standard media upload
sub media {
	my $self = shift;
	return $self->redirect_to('/') unless $self->session('user');
	my $user = $self->session('user');
	
	# return value not ideal here - needs to be AJAXy otherwise there's
	# a risk of losing content
	return $self->redirect_to('/admin/')
      unless my $upload = $self->param('upload');
    my $size 	= $upload->size;
    my $fn 		= $upload->filename;
    my $headers = $upload->headers;

	my $dt 		= DateTime->now();
	my $year 	= $dt->year;
	my $month 	= $dt->month;

	my $upload_path = "public/uploads/$year/$month";

	make_path( $upload_path, { verbose => 0, mode => 0755, error => \my $err} );
	# slightly awkward error checking to see if path has been created
	if (@$err) {
		for my $diag (@$err) {
			my ($file, $message) = %$diag;
			if ($file eq '') {
		    	$self->render_exception("General upload error: $message");
		  	} else {
		    	$self->render_exception("Problem unlinking $file: $message");
		  }
		}
	}

	if ($upload->move_to("$upload_path/$fn")) {
		# add to collection in db
		my $db      = $self->db;
		my $uploads = $db->uploads;

		my $id = $uploads->insert({ 
	    	path => $upload_path,
	    	size => $size,
	    	filename => $fn,
	    	date_added => time(),
    	});

		$self->render_text("upload successful!");
	} else {
	    $self->render_exception("Couldn't create file - please check permissions & try again");
	}
}

1;