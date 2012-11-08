package MojoPub;
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugin::Config;
use MojoPub::Auth;
use MongoDB::Connection;

# This method will run once at server start
sub startup {
  my $self = shift;

  # Initialise config file
  my $config = $self->plugin('Config');

  $self->secret('mojopub is awesome!');

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');

  # helper for DB connection, as per https://github.com/kraih/mojo/wiki/Using-mongodb
  # see also: http://search.cpan.org/~madcat/Mojolicious-Plugin-Mongodb-1.13/
  $self->attr(db => sub { 
      MongoDB::Connection
          ->new(host => $config->{database_host})
          ->get_database($config->{database_name});
  });
  $self->helper('db' => sub { shift->app->db });

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('render#bloghome');

  my $users = MojoPub::Auth->new;
  $self->helper(users => sub { return $users });

  # Login functions

  $r->get('/login')->to( 'auth#login', message => '', user => '' );
  $r->post('/login' => sub {
    my $self = shift;

    my $user = $self->param('user') || '';
    my $pass = $self->param('pass') || '';
    return $self->render(message => 'error!') unless $self->users->check($user, $pass);

    $self->session(user => $user);
    $self->flash(message => 'Thanks for logging in.');
    $self->redirect_to('/admin');
  } => 'auth/login');

  $r->get('/logout' => sub {
    my $self = shift;
    $self->session(expires => 1);
    $self->redirect_to('/');
  });

  # ADMIN - protected area
  $r->get('/admin/')->to('admin#admin');
  $r->get('/admin/add')->to('admin#addpost');
  # $r->post('/admin/publish')->to('save#publishpost');

  $r->post('/admin/savepost')->to('save#savepost');
  $r->get('/admin/draft')->to('save#draft');
  $r->get('/admin/publish')->to('save#publish');

  $r->get('/admin/edit')->to('admin#editpost');
  # $r->post('/admin/edit')->to('save#updatepost');
  # $r->post('/admin/savedraft')->to('save#savedraft');

  $r->get('/admin/posts')->to('admin#posts');


  
  # Main router for blog posts/pages

  $r->route('/:name', name => qr![-0-9a-zA-Z]+!, format => 0)->to('render#blogpost');



}

1;