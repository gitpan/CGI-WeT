#
# $Id: News.pm,v 1.9 1999/05/30 16:49:33 jsmith Exp $
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
# The author may be reached at <jsmith@jamesmith.com>
#

package CGI::WeT::Modules::News;

use strict;
use Carp;
use vars qw($VERSION);

( $VERSION ) = '$Revision: 1.9 $ ' =~ /\$Revision:\s+([^\s]+)/;

=pod 

=head1 NAME

CGI::WeT::Modules::News - Extensions to engine to allow article management

=head1 SYNOPSIS

    use CGI::WeT::Modules::News ();


=head1 DESCRIPTION

This module provides rendering constructs to allow navigation through a set
of articles.  Support is provided for multiple types of articles in multiple
groupings (or channels).

=head1 EXTENSIONS

=over 4

=item CGI::WeT::Modules::News::initialize($engine, $r)

This subroutine will initialize the engine passed as $engine with information
from Apache (passed as $r).  The base URL for articles is set with the
following.

    PerlSetVar WeT_NewsURL /baseURL/

This is available for building URLs as @@NEWS@@.  For example, general articles
are under the URL returned by

    $engine->url('@@NEWS@@/general/');

The directory may likewise be found by using

    $engine->filename($engine->url('@@NEWS@@/general/'));

=cut

sub initialize {
    my $engine = shift;
    my $r = shift;

    if($engine->{'MOD_PERL'}) {
	$engine->{'URLBASES'}->{'NEWS'} = $r->dir_config('WeT_NewsURL');
    }
    return 1; 
}

=pod

=item NEWS_SUMMARY

This extension will insert a summary of available news items starting with the
most recent (ordered by submission time).  The top of the content stack is 
applied to each item as a template.

The template used is called with four elements on the content stack:
Title, Date, Author, and Summary (Title on top of stack).
The available arguments for controlling NEWS_SUMMARY are

=over 4

=item channel

This argument specifies which channel to collect items from.  This defaults
to `general.'

=item category

This argument specifies which category to collect items from.  Only one
category may be specified at this time.  There is no way to block items marked
as `all.'  The default category is `all.'

=item link

If this is set to `title,' the title will be made a link.  No other value has
an effect.

=item number

This tells NEWS_SUMMARY how many items to put in the list.  There is no default
for this argument, so one must be supplied.

=back 4

=cut

# ` for Emacs
# ' for Emacs

sub CGI::WeT::Modules::NEWS_SUMMARY {
    my $engine = shift;

    my $format = $engine->content_pop;
    my $dir =  $engine->filename(
				 $engine->url(
					      '@@NEWS@@/',
					      $engine->argument('channel') ||
					      'general'
					      )
				 );
    my(@files, @output);

    if(-e $dir) {
	my $category = $engine->argument('category');
	opendir OD, "$dir" || return '';
	(@files) = grep(/^\d/ && /\.thtml$/, readdir(OD));
	closedir OD;
	(@files) = sort grep(/$category\.thtml$/ ||
			/\d\.thtml$/, @files)
	    if($engine->argument('category'));
    }

    @files = splice(@files, -$engine->argument('number'))
	if $engine->argument('number') < @files;

    while(@files) {
	my $file = pop @files;
	my $headers = { };
	my(@body, $text, $imgtag, $url, $bt, $et, $key, $val, $fullstory);
	my($picurl);

	open IN, "<$dir/$file";
	while(<IN>) {
	    last if /^\s*$/ || /^\s\#/;
	    chomp;
	    
	    if(/^[A-Za-z_]+:/) {
                ($key, $val) = split(/\s*:\s*/,$_,2);
            } else {
                $val = " $_";
            }
            $$headers{$key} .= $val;
        }
        @body = (<IN>);
        chomp(@body);
        close IN;

	$text = join(" ", @body) . "<p>";
        $text =~ /^(.*?)<p>/;
        $text = $1;

	#
        # set up the call to the layout for this news item
        #

	$url = $engine->url(
			    '@@NEWS@@/',
			    $engine->argument('channel') || 'general',
			    "/$file"
			    );
	$bt = '';
	$et = '';
	if($engine->argument('size')) {
	    $bt = "<font size=" . $engine->argument('size') . ">";
	    $et = "</font>";
	}

	$fullstory = "<p>$bt <a href=\"$url\">Full Story</a>";
	$fullstory .= " by $$headers{Link}" if $$headers{Link};
	$fullstory .= "$et";

	if($engine->argument('icons')) {
	    $picurl = $engine->url(
				   '@@GRAPHICS@@/',
				   $engine->argument('channel') || 'general',
				   , '/',
				   $engine->argument('icons'), '/',
				   $$headers{'Category'},
				   $engine->argument('icon_suffix')
				   );
	    $imgtag = "<img src=\"$picurl\"";
	    foreach (qw(width height align valign hspace vspace)) {
		$imgtag .= " $_=" . $engine->argument($_)
		    if $engine->argument($_);
	    }
	    $imgtag .= " border=0>";
	}

	$engine->content_push(
			      [ $imgtag, $text, $fullstory ],
			      [ $$headers{Author} || '' ],
			      [ $$headers{Date} ],
			      );
	if($engine->argument('link') eq 'title') {
	    $engine->content_push(
				  [ "<a href=\"$url\">$$headers{Title}</a>" ]
				  );
	} else {
	    $engine->content_push(
				  [ $$headers{Title} ]
				  );
	}
	
	$engine->content_push($format);

	push(@output, $engine->render_content);
    }
    return @output;
}

=pod

=item NEWS_NEXT

This extension is like CGI::WeT::Modules::Basic's B<LINK> in that the top of
the content stack is made into a link.  The location is determined by the
values of the arguments.

=over 4

=item channel

See B<NEWS_SUMMARY>

=item type

This can be either `story' or `response.'  If `story,' then the articles
in the top level are looked at.  Otherwise, the articles in the current
directory are examined.

=item sequence

This can be either `next' or `prev.'

=back 4

=cut

# ' for Emacs
# ` for Emacs

sub CGI::WeT::Modules::NEWS_NEXT {
    my $engine = shift;

    my($dir, @files);

    my $url = $engine->{'URI'};
    my $baseurl = $engine->url('@@NEWS@@/',
			       $engine->argument('channel') || 'general'
			       );
    $url =~ s,^$baseurl,,;
    if($engine->argument('type') eq 'story') {
	$url =~ m,/?([^/]+)\.(dir|thtml),;
        $url = $1;
        $dir = '';
    } elsif($engine->argument('type') eq 'response') {
	$dir = $url;
        $dir =~ s,(/[^/]*)$,,;
        $url =~ m,/([^/]+)\.(dir|thtml)$,;
        $url = $1;
    }
    opendir OD, $engine->filename($engine->url($baseurl, '/', $dir));
    (@files) = sort grep(/^\d/ && /\.thtml$/, readdir(OD));
    closedir OD;
    if(@files) {
	use integer;
	my($left, $right) = (0, scalar(@files));
        my($t, $p) = ($url =~ /(\d+)\.(\d+)/);
	my($mid, $tt, $tp);
        while($left < $right) {
            $mid = ($left + $right) / 2;
            ($tt, $tp) = $files[$mid] =~ /(\d+)\.(\d+)/;
            if($tt == $t) {
                last if($tp == $p);
                if($tp < $p) {
                    $left = $mid;
                } else {
                    $right = $mid;
                }
            } elsif($tt < $t) {
                $left = $mid;
            } else {
                $right = $mid;
            }
        }

        if($engine->argument('sequence') eq 'next') {
            $mid++;
        } elsif($engine->argument('sequence') eq 'prev') {
            $mid--;
        } else {
            $mid = -1;
        }
        if($mid < 0 || $mid > $#files) {
            $engine->content_pop;
            return '';
        } else {
	    $engine->content_push(
				  [ "[LINK location=$baseurl/$dir/$files[$mid]]" ]
				  );
	    return $engine->render_content;
	}
    } else {
	$engine->content_pop;
        return '';
    }
}

sub CGI::WeT::Modules::NEWS_RESPONSE {
    my $engine = shift;

    my $url = $engine->{'URI'};
    my $baseurl = $engine->url('@@NEWS@@');
    $url =~ s,^$baseurl,,;
    $url = $engine->url($engine->argument('location')) . "?article=$url";
    $engine->content_push([ "[LINK location=$url]" ]);
    return $engine->render_content;
}

sub CGI::WeT::Modules::NEWS_UP_LEVEL {
    my $engine = shift;

    my $url = $engine->{'URI'};
    my $baseurl = $engine->url('');
    $url =~ s,^$baseurl,,;
    $url =~ s,\.dir/[^/]+\.thtml,\.thtml,;
    $engine->content_push([ "[LINK location=$url]" ]);
    return $engine->render_content;
}

sub CGI::WeT::Modules::NEWS_LIST_RESPONSES {
    my $engine = shift;

    my $url = $engine->{'URI'};
    $url =~ s,\.thtml$,\.dir,;
    return ("<dl>", &NewsListLevel($engine, $url, 
				   $engine->argument('depth')), 
	    "</dl>");
}

sub NewsListLevel { 
    my $engine = shift;
    my($url, $depth) = @_;

    return '' unless $depth;

    my(@output, $headers, $f);

    opendir OD, $engine->filename($url);
    my(@files) = grep(/^\d/ && /\.thtml$/, readdir(OD));
    close OD;

    foreach $f (@files) {
        my $headers = {};
	my($key, $val);
	open IN, "<" . $engine->filename("$url/$f");
	while(<IN>) {
	    last if /^\s*$/ || /^\s\#/;
	    chomp;
	    
	    if(/^[A-Za-z_]+:/) {
                ($key, $val) = split(/\s*:\s*/,$_,2);
            } else {
                $val = " $_";
            }
            $$headers{$key} .= $val;
        }

	push(@output, "<dt><a href=\"$url/$f\">$$headers{Title}</a>",
	     "<small>$$headers{Date}</small> by $$headers{Link}");
	$f =~ s,\.thtml$,\.dir,;
	if(-e $engine->filename("$url/$f")) {
	    push(@output, "<dl>", &NewsListLevel($engine, "$url/$f", $depth-1),
		 "</dl>");
	}
    }
    return @output;
}

1;
