#
# $Id: User.pm,v 1.2 1999/03/21 02:32:06 jsmith Exp $
#
# Author: James G. Smith
#
# Copyright (C) 1999
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc.,
# 675 Mass Ave, Cambridge, MA 02139, USA.
#
# The author may be reached at <j-smith@physics.tamu.edu>
#

package CGI::WeT::User;

use strict;
use Carp;
use vars qw($VERSION);
use integer;

$VERSION = '0.6.3';

=pod

=head1 NAME

CGI::WeT::User - User database interface for CGI::WeT

=head1 SYNOPSIS

    use CGI::WeT::User ();

=head1 DESCRIPTION

This module provides the CGI::WeT package with access to the user database
used for authentication.  This allows other scripts and modules to interact
with user information when pages have been authenticated.

To make full use of this module, one of the various CGI::WeT::User::DBI::*
modules must be compiled also. (Here CGI::WeT::User::DBI is not a reference
to the more well known DBI:: package though work is progressing on
CGI::WeT::User::DBI::DBI.)

CGI::WeT::User will query each available module under
CGI::WeT::User::DBI:: in turn until one returns a defined reference.  To
only use a particular database when several might be available, use the

    PerlSetVar WeT_UserDB <DBI Module>

configuration directive.  This will cause CGI::WeT::User to only query the
CGI::WeT::User::DBI::<DBI Module> module.

See the documentation for the particular database interface being used for more
requirements or configuration directives.

To retrieve information on a user, use the following call:

    $user = new CGI::WeT::User ($engine, 'username' => $ENV{'REMOTE_USER'});

where $engine is the CGI::WeT::Engine object being used to render the page.

=cut
    ;

sub new {
    my $class = shift;
    my $engine = shift;
    my $r;
    my $dbi;
    my $self = {};
    my(@query) = @_;

    if(@query == 0) {
	@query = ('username' => $ENV{'REMOTE_USER'});
    }

    unless(ref $engine) {
	if(defined $engine) {
	    $self = { ($engine, @query) };
	} else {
	    $self = { (@query) };
	}
    } elsif($engine->{'USER'}->{'DBI'}) {
	# query the last one that worked...
	my(@res) = $engine->{'USER'}->{'DBI'}->query(@query);
	if(@res == 1) {
	    $self = $res[0];
	}
    } elsif($engine->{'MOD_PERL'} &&
	    ($r = Apache->request) &&
	    ($dbi = $r->dir_config('WeT_UserDB'))) {
	no strict;
	$engine->{'USER'}->{'DBI'} =
	    new { "CGI::WeT::User::DBI::$dbi" };
	my(@res) = $engine->{'USER'}->{'DBI'}->query(@query);
	if(@res == 1) {
	    $self = $res[0];
	}
    } else {
	my(@res) = ();
	my(@dbis) = map(/(.*)::$/,
			keys %CGI::WeT::User::DBI::
			);
	while(@dbis && @res != 1) {
	    $dbi = shift @dbis;
	    no strict;
	    $engine->{'USER'}->{'DBI'} =
		new { "CGI::WeT::User::DBI::$dbi" };
	    my(@res) = $engine->{'USER'}->{'DBI'}->query(@query);
	}
	if(@res == 1) {
	    $self = $res[0];
	}
    }
  
#    $self->{'CONNECTION'} = $engine->{'USER'}->{'DBI'};
  
    if(defined $$self{'gn'}) {
	my $nname;
	if(ref $self->{'gn'}) {
	    $nname = $self->{'gn'}->[0];
	} else {
	    $nname = $self->{'gn'};
	}
	if(defined $$self{'sn'}) {
	    $nname .= " ";
	    if(ref $self->{'sn'}) {
		$nname .= $self->{'sn'}->[0];
	    } else {
		$nname .= $self->{'sn'};
	    }
	    $self->{'familiarName'} = $nname;
	} else {
	    my $name;
	    if(ref $self->{'cn'}) {
		$name = $self->{'cn'}->[0];
	    } else {
		$name = $self->{'cn'};
	    }
	    my @names = split(/\s+/, $name);
	    pop(@names) if ($names[$#names] =~ /^I+$/i);
	    pop(@names) if ($names[$#names] =~ /^[js]r$/i);
	    $self->{'familiarName'} = "$nname $names[$#names]";
	}
    } elsif(ref $self->{'cn'}) {
	$self->{'familiarName'} = $self->{'cn'}->[0];
    } else {
	$self->{'familiarName'} = $self->{'cn'};
    }

    bless $self, $class;
    return $self;
}

1;
