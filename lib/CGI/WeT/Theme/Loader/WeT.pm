#
# $Id: Loader-Wet.pm,v 1.3 1999/03/06 20:07:31 jsmith Exp $
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

package CGI::WeT::Theme::Loader::WeT;

use strict;
use Carp;
use vars qw($VERSION);

$VERSION = '0.6.2';

=pod

=head1 NAME

CGI::WeT::Theme::Loader::WeT - Module to load pre-0.6 themes

=head1 SYNOPSIS

    use CGI::WeT::Theme::Loader::WeT ();

=head1 DESCRIPTION

=cut

sub factory {
    my $this = shift;
    my $theme = shift;
    my $codedir;
    my $themedir;
    my $url;
    my $self = new CGI::WeT::Theme::Aux::ThemeDef;
    my $r;

    if($ENV{MOD_PERL}) {
	$r = Apache->request;
	$themedir = $r->dir_config('WeT_WeTThemeLoaderURL');
	$codedir = $r->dir_config('WeT_WeTThemeCodeDir') || 
	    $r->document_root . "/$themedir";
	$self->{'URLBASES'}->{'THEMEDIR'} = "$themedir/$theme";
	$self->{'URLBASES'}->{'GRAPHICS'} = "$themedir/$theme/images";
    } else {
    }

    if(defined & { "CGI::WeT::Theme::Loader::WeT::$theme\::Init" }) {
	no strict;
	$self->{'DEFINITION'} = 
	    & { "CGI::WeT::Theme::Loader::WeT::$theme\::Init" } ();
    } else {
	return undef unless(-e "$codedir/$theme/main_config.pl");
	require "$codedir/$theme/main_config.pl";
	no strict;
	$self->{'DEFINITION'} = 
	    & { "CGI::WeT::Theme::Loader::WeT::$theme\::Init" } ();
    }
    
    if(defined & { "CGI::WeT::Theme::Loader::$theme\::SiteMap" }) {
	no strict;
	$self->{'SITEMAP'} = new CGI::WeT::Theme::Aux::SiteMap
	    & { "CGI::WeT::Theme::Loader::WeT::$theme\::SiteMap" };
    } elsif(-e "$codedir/$theme/sitemap.pl") {
	require "$codedir/$theme/sitemap.pl";
	no strict;
	$self->{'SITEMAP'} = new CGI::WeT::Theme::Aux::SiteMap
	    & { "CGI::WeT::Theme::Loader::WeT::$theme\::SiteMap" };
    } else {
	$self->{'SITEMAP'} = new CGI::WeT::Theme::Aux::SiteMap;
    }

    if($ENV{MOD_PERL} && $r->uri =~ /^([^\?]*)/) { 
	$url = $1;
    } elsif($ENV{'REQUEST_URI'} =~ /^([^\?]*)/) {
	$url = $1;
    } else {
	$url = '/';
    }

    if(-e "$codedir/$theme/navmap.txt") {
	open IN, "<$codedir/$theme/navmap.txt";
	my @nav = (<IN>);
	close IN;
	chomp(@nav);

	my @urlparts = split("/", $url);
	my @paths = grep(m|^$url|, @nav);
	my $myurl;
	while(@urlparts && !@paths) {
	    pop @urlparts;
	    $myurl = join("/", @urlparts);
	    @paths = grep(/^$myurl\/?/, @nav);
	}

	my($key, $p, @ps, %lengths);
	foreach (@paths) {
	    ($key, $p) = split(/:/, $_, 2);
	    (@ps) = split(/\|/, $p);
	    $lengths{"$#ps"} .= " $key ";
	}
	
	my $urlpath = (split(/\s+/, $lengths{
	    (sort { $a > $b } (keys %lengths))[0]
	    }))[1];

	$self->{'NAVPATH'} = 
	    (split(":", (grep(/^$urlpath\/?:/,@nav))[0], 2))[1];
    }

    return $self;
}

sub list_themes {
    my($r, $themedir, $codedir);
    my(@themes);

    if($ENV{MOD_PERL}) {
	$r = Apache->request;
	$themedir = $r->dir_config('WeT_WeTThemeLoaderURL');
	$codedir = $r->dir_config('WeT_WeTThemeCodeDir') || 
	    $r->document_root . "/$themedir";
    } else {
    }

    return undef unless -e "$codedir" && -d "$codedir";
    opendir OD, "$codedir";
    @themes = grep(-e "$codedir/$_" && -d "$codedir/$_" 
		   && -e "$codedir/$_/main_config.pl",
		   readdir(OD));
    return @themes;
}
