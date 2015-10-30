package WebService::Aria2::RPC;

use Moose;


#############################################################################
# Meta
#############################################################################

our $VERSION = '0.01';


#############################################################################
# Public Accessors
#############################################################################

has secret => 
( 
  is      => 'rw', 
  isa     => 'Str',
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


#############################################################################
# Object Methods
#############################################################################


#############################################################################
# Public Methods
#############################################################################

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
# See: http://aria2.sourceforge.net/manual/en/html/aria2c.html#aria2.pauseAll
sub pause
{
  my ( $self, $gid ) = @_;

  if ( defined $gid )
  {
    return $self->call( "aria2.pause", $gid );
  }

  return $self->call( "aria2.pauseAll" );
}


# Unpause a download
# See: http://aria2.sourceforge.net/manual/en/html/aria2c.html#aria2.unpause
# See: http://aria2.sourceforge.net/manual/en/html/aria2c.html#aria2.unpauseAll
sub unpause
{
  my ( $self, $gid ) = @_;

  if ( defined $gid )
  {
    return $self->call( "aria2.unpause", $gid );
  }

  return $self->call( "aria2.unpauseAll" );
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

# Format the secret token
sub _secret_token
{
  my ( $self ) = @_;

  return if ! defined $self->secret;

  # If a secret value is configured, generate a secret token to include at the front of
  # every rpc request
  # See: http://aria2.sourceforge.net/manual/en/html/aria2c.html#rpc-auth
  return sprintf "token:%s", $self->secret;
}


1;
