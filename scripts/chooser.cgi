#! /usr/bin/perl

#
# $Id: chooser.cgi,v 1.7 1999/05/30 16:52:35 jsmith Exp $
#
# Author: James G. Smith
#
# Copyright (C) 1998, 1999
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the Artistic Licence.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the Artistic License for more details.
#
# The author may be reached at <jsmith@jamesmith.com>
#

{
my $engine = new CGI::WeT::Engine;

$engine->internal_use_only;

my $theme = $engine->argument('theme') || $engine->{'DEFAULT_THEME'};

my $r = Apache->request;

my $urlbase = $engine->url('@@TOP@@');

$urlbase =~ s{/[^/]*} {/};   # get to the overall directory...

if(defined $ENV{HTTP_REFERER}) {
    $location = $ENV{HTTP_REFERER};
} elsif($ENV{SERVER_PORT} eq '80') {
    $location = "http://$ENV{SERVER_NAME}$urlbase";
} else {
    $location = "http://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$urlbase";
}

$r->cgi_header_out('Set-Cookie' =>
  "theme=$theme; path=$urlbase; domain=$ENV{SERVER_NAME}; expires=Fri 31 Dec 99 23:59:59 GMT");
$r->cgi_header_out('Location' => $location);
}
