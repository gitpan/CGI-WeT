#
# $Id: Chooser.pm,v 1.1 1999/11/19 05:41:18 jsmith Exp $
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

package CGI::WeT::Chooser;

use strict;

use Apache;
use CGI::Cookie;

sub handler ($$) {
  my $class = shift;
  my $r = shift;

  my %params = $r->method eq 'POST' ? $r->content : $r->args;

  my $theme = $params{theme};

  unless($theme) {
    my $cookies = $r->headers_in->{Cookie};
    my @cookies = split(/;\s*/, $cookies);
    while(@cookies && !$theme) {
      my $t = shift @cookies;
      my($k, $v) = split(/=/, $t, 2);
      $k =~ s{%(..)}{chr(hex($1))}ge;
      next unless $k eq 'theme';
      $v =~ s{%(..)}{chr(hex($1))}ge;
      $theme = $v;
    } 
  }

  $theme = $r->subprocess_env('DEFAULT_THEME') unless $theme;

  my $engine = new CGI::WeT::Engine;

  $engine->internal_use_only;

  my $urlbase = $engine->url('@@TOP@@');

  $urlbase =~ s{/[^/]*} {/};   # get to the overall directory...

  my $location = $r->subprocess_env('HTTP_REFERER');

  unless($location) {
    if($r->get_server_port == 80) {
      $location = join('', 'http://', $r->get_server_name, $urlbase);
    } else {
      $location = join('', 'http://', $r->get_server_name, 
                                 ':', $r->get_server_port, $urlbase);
    }
  }
  
  $r->header_out('Set-Cookie' =>
    CGI::Cookie->new(-name => 'theme',
                     -value => $theme,
                     -domain => $r->get_server_name, 
                     -path => $urlbase,
                     -expires => '+12M'
                    ) );
  $r->header_out('Location' => $location);
  $r->send_http_header;
  return Apache::OK;
}

1;
__END__
=pod

=head1 NAME

CGI::WeT::Chooser - Cookie setter for theme selection

=head1 SYNOPSIS

  <Location "/Chooser">
    SetHandler perl-script
    PerlHandler CGI::WeT::Chooser
  </Location>

=head1 DESCRIPTION

CGI::WeT::Chooser replaces the scripts/chooser.cgi script in version 0.70
and earlier.  The theme selector provided in distributions with
CGI::WeT::Chooser will refer to @@TOP@@/Chooser.

=head1 SEE ALSO

perl(1),
CGI::WeT::*(3),

CGI::WeT notes at C<http://www.jamesmith.com/cgi-wet/>

=head1 SUPPORT

Please send any questions or comments about CGI::WeT to me at
jsmith@jamesmith.com.

=head1 AUTHORS

 Written by James G. Smith.
 Copyright (C) 1999.  Released under the Artistic License.

=cut

