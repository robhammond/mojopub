package MojoPub::Auth;
use Mojo::Base 'Mojolicious::Controller';
use strict;
use warnings;

my $USERS = {
    rob    => 'test',
};

sub new { bless {}, shift }

sub check {
	my ($self, $user, $pass) = @_;

	# Success
	return 1 if $USERS->{$user} && $USERS->{$user} eq $pass;

	# Fail
	return;
}

sub login {
	my $self = shift;

	$self->render(message => 'blank');
}

1;
