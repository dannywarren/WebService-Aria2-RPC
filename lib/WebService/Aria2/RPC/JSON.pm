package WebService::Aria2::RPC::JSON;

use Moose;
extends 'WebService::Aria2::RPC';

use JSON::RPC::Legacy::Client;


#############################################################################
# Meta
#############################################################################

our $VERSION = '0.01';


#############################################################################
# Public Accessors
#############################################################################

has '+uri' => 
( 
  default => 'http://localhost:6800/jsonrpc',
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

has '+rpc' => 
(
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
