package WebService::Aria2;

use Moose;

use JSON::RPC::Legacy::Client;


#############################################################################
# Meta
#############################################################################

our $VERSION = '0.01';


#############################################################################
# Public Accessors
#############################################################################

has uri => 
( 
  is      => 'rw', 
  isa     => 'Str', 
  default => 'http://localhost:6800/jsonrpc',
);

has secret => 
( 
  is  => 'rw', 
  isa => 'Str',
);

has max_results =>
(
  is      => 'rw',
  isa     => 'Int',
  default => 99,
);


#############################################################################
# Private Accessors
#############################################################################

has counter => 
(
  is       => 'rw', 
  isa      => 'Int',
  default  => 0,
);

has rpc => 
(
  is         => 'rw', 
  isa        => 'JSON::RPC::Legacy::Client',
  lazy_build => 1,
);


#############################################################################
# Object Methods
#############################################################################

# Initialize the rpc client instance
sub _build_rpc 
{
  my ( $self ) = @_;

  my $rpc = JSON::RPC::Legacy::Client->new();

  return $rpc;
}


#############################################################################
# Public Methods
#############################################################################

# Base method for talking to aria2 via json-rpc
sub call
{
  my ( $self, $method, @params ) = @_;

  # Initialize the rpc if not already done
  if ( ! defined $self->rpc )
  {
    $self->init;
  }

  # Pass along the secret token
  if ( defined $self->secret )
  {
    # If a secret value is configured, generate a secret token to include at the front of
    # every rpc request
    # See: http://aria2.sourceforge.net/manual/en/html/aria2c.html#rpc-auth
    my $secret_token = sprintf "token:%s", $self->secret;

    # Add the secret token to the front of the parameters list
    unshift @params, $secret_token;
  }

  # Increment the request counter
  $self->_increment_counter;

  # Make the json-rpc call
  my $response = $self->rpc->call
  (
    $self->uri,
    {
      method => $method,
      params => \@params,
    },
  );

  # Handle low level protocol errors
  if ( ! defined $response )
  {
    warn "ERROR: %s\n", $self->rpc->status_line;
    return;
  }

  # Handle errors returned from aria2
  if ( $response->is_error )
  {
    # Grab the error string
    my $error = $response->error_message;

    # If the error string is an object, we need to grab the message from it
    $error = $error->{message} if ref $error;

    # Display error and bail
    warn "ERROR: %s\n", $error;
    return;
  }

  # Otherwise, return the result
  return $response->result;
}


# Return the aria2 version
# See: http://aria2.sourceforge.net/manual/en/html/aria2c.html#aria2.getVersion
sub get_version
{
  my ( $self ) = @_;

  return $self->call( "aria2.getVersion" );
}


# Add a uri to download
# See: http://aria2.sourceforge.net/manual/en/html/aria2c.html#aria2.addUri
sub add_uri
{
  my ( $self, $uri ) = @_;

  return if ! defined $uri;

  return $self->call( "aria2.addUri", [ $uri ] );
}


# Return a list of active (started) downloads
# See: http://aria2.sourceforge.net/manual/en/html/aria2c.html#aria2.tellActive
sub get_active
{
  my ( $self ) = @_;

  return $self->call( "aria2.tellActive" );
}


# Return a list of waiting (paused) downloads
# See: http://aria2.sourceforge.net/manual/en/html/aria2c.html#aria2.tellWaiting
sub get_waiting
{
  my ( $self ) = @_;

  return $self->call( "aria2.tellWaiting", 0, $self->max_results );
}


# Return a list of stopped downloads
# See: http://aria2.sourceforge.net/manual/en/html/aria2c.html#aria2.tellStopped
sub get_stopped
{
  my ( $self ) = @_;

  return $self->call( "aria2.tellStopped", 0, $self->max_results );
}


# Pause a download
# See: http://aria2.sourceforge.net/manual/en/html/aria2c.html#aria2.pause
sub pause
{
  my ( $self, $gid ) = @_;

  return if ! defined $gid;

  return $self->call( "aria2.pause", $gid );
}


# Unpause a download
# See: http://aria2.sourceforge.net/manual/en/html/aria2c.html#aria2.unpause
sub unpause
{
  my ( $self, $gid ) = @_;

  return if ! defined $gid;

  return $self->call( "aria2.unpause", $gid );
}


# Purge completed downloads
# See: http://aria2.sourceforge.net/manual/en/html/aria2c.html#aria2.purgeDownloadResult
# See: http://aria2.sourceforge.net/manual/en/html/aria2c.html#aria2.removeDownloadResult
sub purge
{
  my ( $self, $gid ) = @_;

  # If a gid was given, purge only that gid
  if ( defined $gid )
  {
    return $self->call( "aria2.removeDownloadResult", $gid );
  }

  # Otherwise, purge all completed downloads
  return $self->call( "aria2.purgeDownloadResult" );
}


#############################################################################
# Private Methods
#############################################################################

# Increment the request counter
sub _increment_counter
{
  my ( $self ) = @_;

  # Bump the counter
  $self->counter( $self->counter + 1 );

  # Use the counter as the next rpc request id
  $self->rpc->id( $self->counter );

  return;
}


1;
