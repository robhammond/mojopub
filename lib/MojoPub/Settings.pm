package MojoPub::Settings;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::Log;

use MongoDB;
use MongoDB::OID;
use DateTime;
use Data::Dumper;

my $log = Mojo::Log->new;


sub savesettings {
	my $self = shift;

	return $self->redirect_to('/') unless $self->session('user');
	my $user  = $self->session('user');

	my $db       = $self->db;
	my $settings = $db->settings;

	# variables
	my $sitename    = $self->param('sitename');
	my $seovisible     = $self->param('seovisible');
	my $relauthor  = $self->param('relauthor');
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
		    	type     => 'post',
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


1;
