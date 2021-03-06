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
	my $posts = $db->get_collection( 'posts' );

	# variables
	my $title    = $self->param('title');
	my $slug     = $self->param('slug');
	my $content  = $self->param('content');
	my $type  	 = $self->param('type');
	my @tags     = split(/, ?/, $self->param('tags'));
	# append any existing tags if present
	my @tags2	 = $self->param('tag') || ();
	push (@tags, @tags2);
	my $comments = $self->param('comments') || 0;
	my $noindex  = $self->param('noindex')  || 0;
	my $nofollow = $self->param('nofollow') || 0;

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
		    	author   => $user,
		    	tags	 => \@tags,
		    	status   => 'draft', # draft by default
		    	type     => $type,
		    	comments => { on => $comments },
		    	noindex  => $noindex,
		    	nofollow => $nofollow,
	    	},
	    	head => {
	    		title 	 => $title,
	    	},
	    	body => {
	    		content  => $content,
	    	},
	    	foot => {

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
			'head.title'   => $title,
			'body.content' => $content,
			'meta.slug'    => $slug,
			'meta.type'    => $type,
			'meta.tags'    => \@tags,
			'meta.noindex' => $noindex,
			'meta.nofollow' => $nofollow,
			'meta.last_updated' => time(),
		}});

		# now route to status
		if ($action eq 'save') {
			$self->flash(message => "Post updated!");
			$self->redirect_to("/admin/edit?id=$id");	
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
	my $posts = $db->get_collection( 'posts' );
	my $id  = $self->param("id");

	# Publish & set a published time
	$posts->update({"_id" => MongoDB::OID->new( value => $id )}, {'$set' => { 
			'meta.status'   => 'live',
			'meta.published' => time(),
	}});

	$self->flash(message => 'Published!');
	$self->redirect_to("/admin/posts");
}

sub draft {
	my $self = shift;

	return $self->redirect_to('/') unless $self->session('user');

	my $user  = $self->session('user');
	my $id = $self->param("id");

	my $db    = $self->db;
	my $posts = $db->get_collection( 'posts' );

	# Change status to draft and update last_updated value
	$posts->update({"_id" => MongoDB::OID->new( value => $id )}, {'$set' => { 
			'meta.status'   => 'draft',
			'meta.last_updated' => time(),
	}});
	$self->flash(message => 'saved!');
	$self->redirect_to("/admin/posts");
}

sub delete {
	my $self = shift;

	return $self->redirect_to('/') unless $self->session('user');

	my $user  = $self->session('user');
	my $id = $self->param("id");

	my $db    = $self->db;
	my $posts = $db->get_collection( 'posts' );

	# Change status to draft and update last_updated value
	$posts->remove( {"_id" => MongoDB::OID->new( value => $id )} );
	$self->flash( message => 'deleted!' );
	$self->redirect_to("/admin/posts");
}

1;
