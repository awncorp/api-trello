# ABSTRACT: Perl 5 API wrapper for Trello
package API::Trello;

use API::Trello::Class;

extends 'API::Trello::Client';

use Carp ();
use Scalar::Util ();

# VERSION

has camelize => (
    is       => 'rw',
    isa      => Int,
    default  => 1,
);

has key => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has token => (
    is       => 'rw',
    isa      => Str,
    required => 0,
);

has identifier => (
    is       => 'rw',
    isa      => Str,
    default  => 'API::Trello (Perl)',
);

has version => (
    is       => 'rw',
    isa      => Int,
    default  => 1,
);

method AUTOLOAD () {
    my ($package, $method) = our $AUTOLOAD =~ /^(.+)::(.+)$/;
    Carp::croak "Undefined subroutine &${package}::$method called"
        unless Scalar::Util::blessed $self && $self->isa(__PACKAGE__);

    my @segments = @_;
    my @results  = ();

    my $camelize = $self->camelize;
    while (my ($path, $param) = splice @segments, 0, 2) {
        $path =~ s/([a-z])_([a-zA-Z])/$1\U$2/g if $camelize and defined $param;
        push @results, $path, defined $param ? $param : ();
    }

    # return new resource instance dynamically
    return $self->resource($method, @results);
}

method BUILD () {
    my $key        = $self->key;
    my $token      = $self->token;
    my $identifier = $self->identifier;
    my $version    = $self->version;
    my $agent      = $self->user_agent;
    my $url        = $self->url;

    $agent->transactor->name($identifier);

    $url->path("/$version");
    $url->query(key => $key, $token ? (token => $token) : ());

    return $self;
}

method PREPARE ($ua, $tx, %args) {
    my $headers = $tx->req->headers;
    my $url     = $tx->req->url;

    # default headers
    $headers->header('Content-Type' => 'application/json');
}

method action ($method, %args) {
    $method = uc($method || 'get');

    # execute transaction and return response
    return $self->$method(%args);
}

method create (%args) {
    # execute transaction and return response
    return $self->POST(%args);
}

method delete (%args) {
    # execute transaction and return response
    return $self->DELETE(%args);
}

method fetch (%args) {
    # execute transaction and return response
    return $self->GET(%args);
}

method resource (@segments) {
    # build new resource instance
    my $instance = __PACKAGE__->new(
        debug      => $self->debug,
        fatal      => $self->fatal,
        retries    => $self->retries,
        timeout    => $self->timeout,
        user_agent => $self->user_agent,
        key        => $self->key,
        token      => $self->token,
        identifier => $self->identifier,
        version    => $self->version,
    );

    # resource locator
    my $url = $instance->url;

    # modify resource locator if possible
    $url->path(join '/', $self->url->path, @segments);

    # return resource instance
    return $instance;
}

method update (%args) {
    # execute transaction and return response
    return $self->PUT(%args);
}

1;

=encoding utf8

=head1 SYNOPSIS

    use API::Trello;

    my $trello = API::Trello->new(
        key        => 'KEY',
        token      => 'TOKEN',
        identifier => 'APPLICATION NAME',
    );

    $trello->debug(1);
    $trello->fatal(1);

    my $board = $trello->boards('4d5ea62fd76a');
    my $results = $board->fetch;

    # after some introspection

    $board->update( ... );

=head1 DESCRIPTION

This distribution provides an object-oriented thin-client library for
interacting with the Trello (L<http://trello.com>) API. For usage and
documentation information visit L<https://trello.com/docs/gettingstarted/index.html>.

=cut

=head1 THIN CLIENT

A thin-client library is advantageous as it has complete API coverage and
can easily adapt to changes in the API with minimal effort. As a thin-client
library, this module does not map specific HTTP requests to specific routines,
nor does it provide parameter validation, pagination, or other conventions
found in typical API client implementations, instead, it simply provides a
simple and consistent mechanism for dynamically generating HTTP requests.
Additionally, this module has support for debugging and retrying API calls as
well as throwing exceptions when 4xx and 5xx server response codes are
returned.

=cut

=head2 Building

    my $board = $trello->boards('4d5ea62fd76a');

    $board->action; # GET /boards/4d5ea62fd76a
    $board->action('head'); # HEAD /boards/4d5ea62fd76a
    $board->action('patch'); # PATCH /boards/4d5ea62fd76a

Building up an HTTP request object is extremely easy, simply call method names
which correspond to the API's path segments in the resource you wish to execute
a request against. This module uses autoloading and returns a new instance with
each method call. The following is the equivalent:

=head2 Chaining

    my $board = $trello->resource('boards', '4d5ea62fd76a');

    # or

    my $boards = $trello->boards;
    my $board  = $boards->resource('4d5ea62fd76a');

    # then

    $board->action('put', %args); # PUT /boards/4d5ea62fd76a

Because each call returns a new API instance configured with a resource locator
based on the supplied parameters, reuse and request isolation are made simple,
i.e., you will only need to configure the client once in your application.

=head2 Fetching

    my $boards = $trello->boards;

    # query-string parameters

    $boards->fetch( query => { ... } );

    # equivalent to

    my $boards = $trello->resource('boards');

    $boards->action( get => ( query => { ... } ) );

This example illustrates how you might fetch an API resource.

=head2 Creating

    my $boards = $trello->boards;

    # content-body parameters

    $boards->create( data => { ... } );

    # query-string parameters

    $boards->create( query => { ... } );

    # equivalent to

    $trello->resource('boards')->action(
        post => ( query => { ... }, data => { ... } )
    );

This example illustrates how you might create a new API resource.

=head2 Updating

    my $boards = $trello->boards;
    my $board  = $boards->resource('4d5ea62fd76a');

    # content-body parameters

    $board->update( data => { ... } );

    # query-string parameters

    $board->update( query => { ... } );

    # or

    my $board = $trello->boards('4d5ea62fd76a');

    $board->update(...);

    # equivalent to

    $trello->resource('boards')->action(
        put => ( query => { ... }, data => { ... } )
    );

This example illustrates how you might update a new API resource.

=head2 Deleting

    my $boards = $trello->boards;
    my $board  = $boards->resource('4d5ea62fd76a');

    # content-body parameters

    $board->delete( data => { ... } );

    # query-string parameters

    $board->delete( query => { ... } );

    # or

    my $board = $trello->boards('4d5ea62fd76a');

    $board->delete(...);

    # equivalent to

    $trello->resource('boards')->action(
        delete => ( query => { ... }, data => { ... } )
    );

This example illustrates how you might delete an API resource.

=cut

=head2 Transacting

    my $boards = $trello->resource('boards', '4d5ea62fd76a');

    my ($results, $transaction) = $boards->action( ... );

    my $request  = $transaction->req;
    my $response = $transaction->res;

    my $headers;

    $headers = $request->headers;
    $headers = $response->headers;

    # etc

This example illustrates how you can access the transaction object used
represent and process the HTTP transaction.

=cut

=attr camelize

    $trello->camelize;
    $trello->camelize(1);

The camelize parameter determines whether HTTP request path parts will be
automatically camelcased.

=cut

=attr identifier

    $trello->identifier;
    $trello->identifier('IDENTIFIER');

The identifier parameter should be set to a string that identifies your application.

=cut

=attr key

    $trello->key;
    $trello->key('KEY');

The key parameter should be set to the account holder's API key.

=cut

=attr token

    $trello->token;
    $trello->token('TOKEN');

The token parameter should be set to the account holder's API access token.

=cut

=attr identifier

    $trello->identifier;
    $trello->identifier('IDENTIFIER');

The identifier parameter should be set using a string to identify your app.

=cut

=attr debug

    $trello->debug;
    $trello->debug(1);

The debug attribute if true prints HTTP requests and responses to standard out.

=cut

=attr fatal

    $trello->fatal;
    $trello->fatal(1);

The fatal attribute if true promotes 4xx and 5xx server response codes to
exceptions, a L<API::Trello::Exception> object.

=cut

=attr retries

    $trello->retries;
    $trello->retries(10);

The retries attribute determines how many times an HTTP request should be
retried if a 4xx or 5xx response is received. This attribute defaults to 0.

=cut

=attr timeout

    $trello->timeout;
    $trello->timeout(5);

The timeout attribute determines how long an HTTP connection should be kept
alive. This attribute defaults to 10.

=cut

=attr url

    $trello->url;
    $trello->url(Mojo::URL->new('https://api.trello.com'));

The url attribute set the base/pre-configured URL object that will be used in
all HTTP requests. This attribute expects a L<Mojo::URL> object.

=cut

=attr user_agent

    $trello->user_agent;
    $trello->user_agent(Mojo::UserAgent->new);

The user_agent attribute set the pre-configured UserAgent object that will be
used in all HTTP requests. This attribute expects a L<Mojo::UserAgent> object.

=cut

=method action

    my $result = $trello->action($verb, %args);

    # e.g.

    $trello->action('head', %args);    # HEAD request
    $trello->action('options', %args); # OPTIONS request
    $trello->action('patch', %args);   # PATCH request


The action method issues a request to the API resource represented by the
object. The first parameter will be used as the HTTP request method. The
arguments, expected to be a list of key/value pairs, will be included in the
request if the key is either C<data> or C<query>.

=cut

=method create

    my $results = $trello->create(%args);

    # or

    $trello->POST(%args);

The create method issues a C<POST> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=cut

=method delete

    my $results = $trello->delete(%args);

    # or

    $trello->DELETE(%args);

The delete method issues a C<DELETE> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=cut

=method fetch

    my $results = $trello->fetch(%args);

    # or

    $trello->GET(%args);

The fetch method issues a C<GET> request to the API resource represented by the
object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=cut

=method update

    my $results = $trello->update(%args);

    # or

    $trello->PUT(%args);

The update method issues a C<PUT> request to the API resource represented by
the object. The arguments, expected to be a list of key/value pairs, will be
included in the request if the key is either C<data> or C<query>.

=cut

=resource actions

    $trello->actions;

The actions method returns a new instance representative of the API
I<actions> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/action/index.html>.

=cut

=resource batch

    $trello->batch;

The batch method returns a new instance representative of the API
I<batch> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/batch/index.html>.

=cut

=resource boards

    $trello->boards;

The boards method returns a new instance representative of the API
I<boards> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/board/index.html>.

=cut

=resource cards

    $trello->cards;

The cards method returns a new instance representative of the API
I<cards> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/card/index.html>.

=cut

=resource checklists

    $trello->checklists;

The checklists method returns a new instance representative of the API
I<checklists> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/checklist/index.html>.

=cut

=resource labels

    $trello->labels;

The labels method returns a new instance representative of the API
I<labels> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/label/index.html>.

=cut

=resource lists

    $trello->lists;

The lists method returns a new instance representative of the API
I<lists> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/list/index.html>.

=cut

=resource members

    $trello->members;

The members method returns a new instance representative of the API
I<members> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/member/index.html>.

=cut

=resource notifications

    $trello->notifications;

The notifications method returns a new instance representative of the API
I<notifications> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/notification/index.html>.

=cut

=resource organizations

    $trello->organizations;

The organizations method returns a new instance representative of the API
I<organizations> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/organization/index.html>.

=cut

=resource search

    $trello->search;

The search method returns a new instance representative of the API
I<search> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/search/index.html>.

=cut

=resource sessions

    $trello->sessions;

The sessions method returns a new instance representative of the API
I<sessions> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/session/index.html>.

=cut

=resource tokens

    $trello->tokens;

The tokens method returns a new instance representative of the API
I<tokens> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/token/index.html>.

=cut

=resource types

    $trello->types;

The types method returns a new instance representative of the API
I<types> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/type/index.html>.

=cut

=resource webhooks

    $trello->webhooks;

The webhooks method returns a new instance representative of the API
I<webhooks> resource requested. This method accepts a list of path
segments which will be used in the HTTP request. The following documentation
can be used to find more information. L<https://trello.com/docs/api/webhook/index.html>.

=cut

