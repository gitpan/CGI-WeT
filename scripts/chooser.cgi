#! /usr/bin/perl

#
# chooser.cgi
#
# Author: James G. Smith
#
# Copyright (C) 1998, 1999
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# The author may be reached at <j-smith@physics.tamu.edu> or
# 1017 Winding Rd., College Station, TX 77840
#

my $engine = new CGI::WeT::Engine;

my $theme = $engine->argument('theme') || $engine->{'DEFAULT_THEME'};

my $r = Apache->request;

my $urlbase = $engine->url('');

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

