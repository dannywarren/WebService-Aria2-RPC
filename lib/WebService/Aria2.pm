package WebService::Aria2;

our $VERSION = '0.01';

use strict;
use warnings;

use JSON::RPC::Legacy::Client;


#############################################################################
# Object Methods
#############################################################################

# Constructor
sub new
{
  my ( $class, %args ) = @_;

  my $self =
  {
    url         => 'http://localhost:6800/jsonrpc',
    secret      => undef,
    rpc         => undef,
    request_id  => 0,
    max_num     => 99,
  };

  return bless $self, $class;
}


#############################################################################
# Public Methods
#############################################################################

# Initialization
sub init
{
  my ( $self ) = @_;

  # Create an instance of our json/rpc client
  $self->{rpc} = JSON::RPC::Legacy::Client->new();

  return;
}


# Base method for talking to aria2 via json-rpc
sub call
{
  my ( $self, $method, @params ) = @_;

  # Initialize the rpc if not already done
  if ( ! defined $self->{rpc} )
  {
    $self->init;
  }

  # Pass along the secret token
  if ( defined $self->{secret} )
  {
    # If a secret value is configured, generate a secret token to include at the front of
    # every rpc request
    # See: http://aria2.sourceforge.net/manual/en/html/aria2c.html#rpc-auth
    my $secret_token = sprintf "token:%s", $self->{secret};

    # Add the secret token to the front of the parameters list
    unshift @params, $secret_token;
  }

  # Bump the request id every time we make a call
  $self->{rpc}->id( $self->{request_id}++ );

  # Make the json-rpc call
  my $response = $self->{rpc}->call
  (
    $self->{url},
    {
      method => $method,
      params => \@params,
    },
  );

  # Handle low level protocol errors
  if ( ! defined $response )
  {
    warn "ERROR: %s\n", $self->{rpc}->status_line;
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

  return $self->call( "aria2.tellWaiting", 0, $self->{max_num} );
}


# Return a list of stopped downloads
# See: http://aria2.sourceforge.net/manual/en/html/aria2c.html#aria2.tellStopped
sub get_stopped
{
  my ( $self ) = @_;

  return $self->call( "aria2.tellStopped", 0, $self->{max_num} );
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


1;
