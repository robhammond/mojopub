package MojoPub::Save;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::Log;

use MongoDB;
use MongoDB::OID;
use DateTime;
use Data::Dumper;

my $log = Mojo::Log->new;


sub savepost {
	my $self = shift;

	return $self->redirect_to('/') unless $self->session('user');
	my $user  = $self->session('user');

	my $db    = $self->db;
	my $posts = $db->posts;

	# variables
	my $title   = $self->param('title');
	my $slug    = $self->param('slug');
	my $content = $self->param('content');
	my @tags    = split(',', $self->param('tags'));

	# actions
	my $action = $self->param('action');
	my $id = $self->param('id') || '';

	
	if ($id eq '') {
		# If no id given, then insert
		$id = $posts->insert({ 
	    	nonce   => MongoDB::OID->new,
	    	meta => {
	    		slug   	 => $slug,
		    	created	 => time(),
		    	last_updated => time(),
		    	title 	 => $title,
		    	content  => $content,
		    	author   => $user,
		    	tags	 => \@tags,
		    	status   => 'draft', # draft by default
		    	type     => 'post',
		    	comments => { on => 0 },
	    	},
    	});

    	# now route to status
		if ($action eq 'save') {
			$self->redirect_to("/admin/");	
		} elsif ($action eq 'publish') {
			$self->redirect_to("/admin/publish?id=$id");
		}
    	
	} else {
		# update if ID exists
		$posts->update({"_id" => MongoDB::OID->new( value => $id )}, {'$set' => { 
			'meta.title'   => $title,
			'meta.content' => $content,
			'meta.slug'    => $slug,
			'meta.tags'    => \@tags,
			'meta.last_updated' => time(),
		}});

		# now route to status
		if ($action eq 'save') {
			$self->redirect_to("/admin/");	
		} elsif ($action eq 'publish') {
			$self->redirect_to("/admin/publish?id=$id");
		}
	}
}

sub publish {
	my $self = shift;

	return $self->redirect_to('/') unless $self->session('user');
	my $user  = $self->session('user');
	
	my $db    = $self->db;
	my $posts = $db->posts;
	my $id  = $self->param("id");

	# Publish & set a published time
	$posts->update({"_id" => MongoDB::OID->new( value => $id )}, {'$set' => { 
			'meta.status'   => 'live',
			'meta.published' => time(),
	}});

	$self->flash(message => 'Published!');
	$self->redirect_to("/admin/");
}

sub draft {
	my $self = shift;

	return $self->redirect_to('/') unless $self->session('user');

	my $user  = $self->session('user');
	my $id = $self->param("id");

	my $db    = $self->db;
	my $posts = $db->posts;

	# Change status to draft and update last_updated value
	$posts->update({"_id" => MongoDB::OID->new( value => $id )}, {'$set' => { 
			'meta.status'   => 'draft',
			'meta.last_updated' => time(),
	}});
	$self->flash(message => 'saved!');
	$self->redirect_to("/admin/");
}

1;
