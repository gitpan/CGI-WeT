#
# $Id: WeT.pm,v 1.8 1999/05/14 01:13:06 jsmith Exp $
#
# Author: James G. Smith
#
# Copyright (C) 1999
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the Artistic Licence.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the Artistic License for more details.
#
# The author may be reached at <jsmith@nostrum.com>
#

package CGI::WeT::Theme::Loader::WeT;

use strict;
use Carp;
use vars qw($VERSION);

( $VERSION ) = '$Revision: 1.8 $ ' =~ /\$Revision:\s+([^\s]+)/;

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

    return undef unless $theme =~ /([^;]+)/;
    $theme = $1;

    if($ENV{MOD_PERL}) {
	$r = Apache->request;
	$themedir = $r->dir_config('WeT_WeTThemeLoaderURL');
	$codedir = $r->dir_config('WeT_WeTThemeCodeDir') || 
	    $r->document_root . "/$themedir";
	$self->{'URLBASES'}->{'THEMEDIR'} = "$themedir/$theme";
	$self->{'URLBASES'}->{'GRAPHICS'} = "$themedir/$theme/images";
    } else {
    }

    if(-e "$codedir/$theme/main_config.pl") {
	require "$codedir/$theme/main_config.pl";
    }
    if(defined & { "CGI::WeT::Theme::Loader::WeT::$theme\::Init" }) {
	no strict;
	$self->{'DEFINITION'} = 
	    & { "CGI::WeT::Theme::Loader::WeT::$theme\::Init" } ();
    } else {
	$self->{'DEFINITION'} = {};
    }
    
    if(-e "$codedir/$theme/sitemap.pl") {
	require "$codedir/$theme/sitemap.pl";
    }
    if(defined & { "CGI::WeT::Theme::Loader::WeT::$theme\::SiteMap" }) {
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
