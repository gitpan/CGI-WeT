#
# $Id: Theme.pm,v 1.3 1999/03/06 20:07:31 jsmith Exp $
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

package CGI::WeT::Theme;

use strict;
use Carp;
use vars qw($VERSION);

$VERSION = '0.6.2';

=pod

=head1 NAME

CGI::WeT::Theme - Theme loader for the CGI::WeT package

=head1 SYNOPSIS

    use CGI::WeT::Theme ();

=head1 DESCRIPTION

This module provides a well-defined interface between the rendering engine and
the theme definition loaders.  It is designed to work with or without
B<mod_perl>.  All theme loader classes must be defined in the
CGI::WeT::Theme::Loader namespace during the construction of a CGI::WeT::Theme
object.

This module is used by the rendering engine and should not be needed outside
of that engine.  This documentation is to aid those building a theme loader.

All theme loaders need the following method defined:

=over 4

=item factory(B<theme>)

This will produce a properly blessed object 
which represents the definition for B<theme>.
If such an object can not be produced (B<theme> not defined by that particular
loader), this will return B<undef>.

=back 4

The object returned by the B<factory> method must provide the following
methods:

=over 4

=item page_type(B<list>)

This function will return an object representing the information needed to
layout a page of the type in B<list>.  Since this is a list, the first
item is most desired while the last is least desired.  It will return the
information for the best desired match it can find.  If none can be returned,
it must return B<undef>.

The object returned by this function must provide B<LAYOUT> and may
provide  B<BODY>, B<CSS>, and B<JAVASCRIPT>.  B<LAYOUT> provides an anonymous
array describing the layout of the page.  B<BODY> returns a hash reference
describing various body attributes.  B<BODY> is deprecated in favor of
B<CSS> which returns a reference to an array with the Cascading
Style Sheet to use for this layout.  B<JAVASCRIPT> returns a reference to
an array with any JavaScript required for this layout.

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;

    my $theme = shift;

    my $self = undef;
    my(@loaders) = map((m/(.*)::$/), 
		       grep(/::$/, keys %CGI::WeT::Theme::Loader::));

    while(scalar(@loaders) && !defined $self) {
	$self = 
	    factory { "CGI::WeT::Theme::Loader::" . shift(@loaders)} ($theme);
    }
    return $self;
}

sub list_themes {
    my(@themes);
    my(@loaders) = map((m/(.*)::$/), 
		       grep(/::$/, keys %CGI::WeT::Theme::Loader::));

    while(@loaders) {
	push(@themes, 
	     list_themes { "CGI::WeT::Theme::Loader::" . shift(@loaders)} ()
	     );
    }

    return @themes;
}

package CGI::WeT::Theme::Aux::PageType;

use vars qw($VERSION $AUTOLOAD);

$VERSION = '0.6.2';

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = { };

    bless $self, $class;

    return $self;
}

sub AUTOLOAD {
    my $self = shift;

    my $name = $AUTOLOAD;
    $name =~ s/.*:://;
    if(exists $self->{$name}) {
	return $self->{$name};
    } else {
	return undef;
    }
}

package CGI::WeT::Theme::Aux::ThemeDef;

use vars qw($VERSION);

$VERSION = '0.6.2';

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = { };

    $self->{'URLBASES'} = { };

    bless $self, $class;

    return $self;
}

sub page_type {
    my $self = shift;
    my $p;

    foreach $p (@_) {
	if(defined $self->{'DEFINITION'}->{$p}) {
	    my $child = new CGI::WeT::Theme::Aux::PageType;
	    map($child->{$_} = $self->{'DEFINITION'}->{$p}->{$_},
		keys % { $self->{'DEFINITION'}->{$p} });
	    return $child;
	}
    }
    return undef;
}

sub SITEMAP {
    my $self = shift;

    return $self->{'SITEMAP'};
}

sub NAVPATH {
    my $self = shift;

    return $self->{'NAVPATH'};
}

package CGI::WeT::Theme::Aux::SiteMap;

use vars qw($VERSION);

$VERSION = '0.6.2';

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = shift || { };

    bless $self, $class;

    return $self;
}

sub add_node{
    my $self = shift;

    my $node = shift;

    $self->{$node} = { };
}

sub submap {
    my $self = shift;
    
    my $node = shift;
    my $sitemap = shift;

    if($sitemap) {
	$self->{$node}->{'content'} = $sitemap;
    } else {
	return new CGI::WeT::Theme::Aux::SiteMap $self->{$node}->{'content'};
    }
}

sub KEYS {
    my $self = shift;

    if(defined $self->{'keys'}) {
	return grep($_ ne 'keys', split(/\|/, $self->{'keys'}));
    } else {
	return sort keys %$self;
    }
}
