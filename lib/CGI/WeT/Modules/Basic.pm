#
# $Id: Basic.pm,v 1.2 1999/03/03 04:27:41 jsmith Exp $
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

package CGI::WeT::Modules::Basic;

use strict;
use Carp;
use vars qw($VERSION);

$VERSION = '0.6';

=pod

=head1 NAME

CGI::WeT::Modules::Basic - Basic rendering engine extensions

=head1 SYNOPSIS

    use CGI::WeT::Modules::Basic ();

=head1 DESCRIPTION

This module provides basic rendering constructs for the engine.
Please be aware that the code supersedes the documentation.  While I have
tried to be accurate there are times that words fail me and a look at the
code is far more enlightening than anything I could cobble together.
This is especially true when trying to write a theme.  Download a theme and
see how someone else did it.  Then try making modifications and see what
happens.

=head1 EXTENSIONS

sub initialize { 1; }

=over 4

=item BODY

This extension will insert the body of the themed HTML into the rendered page.

=cut

sub CGI::WeT::Modules::BODY {
    my $engine = shift;

    return join(" ", @ { $engine->{BODY} || [ ] } );
}

=pod

=item HBOX

This extension builds a box on the page by placing the contents in a
<table>...</table> construct.  Available arguments are: width, cellspacing,
cellpadding, border, height, and bgcolor.

=cut

sub CGI::WeT::Modules::HBOX {
    my $engine = shift;

    my(@output);

    push(@output, "<table");
    foreach ('width', 'cellspacing', 'cellpadding', 'border',
             'height') {
        push(@output, " $_=", $engine->argument($_))
            if $engine->argument($_) !~ /^\s*$/;
    }

    push(@output, " bgcolor=\"#", $engine->argument('bgcolor'), "\"")
        if defined $engine->argument('bgcolor');
    push(@output, ">");
    push(@output, $engine->render_content);
    push(@output, "</table>");
    return @output;
}

=pod

=item VBOX

This extension places its contents in a smaller box which is contained in a
B<LINE>.  Available arguments are: width, valign, colspan, rowspan, height,
align, background, bgcolor.

=cut

sub CGI::WeT::Modules::VBOX {
    my $engine = shift;

    my(@output);

    push(@output, "<td");
    foreach ('width', 'valign', 'colspan', 'rowspan', 'height', 'align',
             'background') {
        push(@output, " $_=", $engine->argument($_))
            if $engine->argument($_) !~ /^\s*$/;
    }

    push(@output, " bgcolor=\"#", $engine->argument('bgcolor'), "\"")
        if defined $engine->argument('bgcolor');
    push(@output, ">");
    push(@output, $engine->render_content);
    push(@output, "</td>");
    return @output;
}

=pod

=item LINE

This extension puts together a set of B<VBOX>s for inclusion in a B<HBOX>.

=cut

sub CGI::WeT::Modules::LINE {
    my $engine = shift;

    return ("<tr>", $engine->render_content, "</tr>");
}

=pod

=item CONTENT

This extension renders the top of the content stack and places the results in
the page.

=cut

sub CGI::WeT::Modules::CONTENT {
    my $engine = shift;

    return($engine->render_content);
}

=pod

=item TEXT

This extension interprets the top of the content stack as plain text and
places it in the page.

=cut

sub CGI::WeT::Modules::TEXT {
    my $engine = shift;

    return join(" ", @ { $engine->content_pop });
}

=pod

=item GRAPHIC

This extension will place a theme dependent graphic image in the page.

=cut

sub CGI::WeT::Modules::GRAPHIC {
    my $engine = shift;

    my($img) = '<img hspace=0 vspace=0 border=0';
    
    $img .= " src=\"" .
	$engine->url('@@GRAPHICS@@/', $engine->argument('location')) .
	    "\"" if defined $engine->argument('location');
    
    foreach ('height', 'width', 'align', 'valign') {
	next unless defined $engine->argument($_);
	$img .= " $_=" . $engine->argument($_);
    }

    return "$img>";
}

=pod

=item HEADERS

This extension places the text of a header line in the page.  Available
arguments are: key, align, size, and color.

=cut

sub CGI::WeT::Modules::HEADERS {
    my $engine = shift;

    my($bt, $et);
    if(defined $engine->argument('key')) {
	if($engine->argument('weight') eq 'strong') {
	    $bt .= "<strong>";
	    $et .= "</strong>";
	}
	if($engine->argument('align') eq 'center') {
	    $bt .= "<center>";
	    $et = "</center>$et";
	}
	if($engine->argument('size') || $engine->argument('color')) {
	    $bt .= "<font";
	    $bt .= " size=" . $engine->argument('size')
		if $engine->argument('size');
	    $bt .= " color=\"#" . $engine->argument('color') . "\"";
	    $bt .= ">";
	    $et = "</font>$et";
	}
	return ($bt, $engine->{'HEADERS'}->{$engine->argument('key')}, $et); 
    } else {
	return '';
    }
}

=pod

=item LINK

This extension places a link relative to the top of the site around the
content at the top of the content stack.  The argument needed is `location.'

=cut

sub CGI::WeT::Modules::LINK {
    my $engine = shift;

    return ('<a href="' . $engine->url($engine->argument('location')) . '">',
	    $engine->render_content,
	    '</a>');
}

=pod

=item DUP

This extension duplicates the top of the content stack.

=cut

sub CGI::WeT::Modules::DUP {
    my $engine = shift;

    $engine->content_push($engine->content_peek);
}

=pod

=item ROT

This extension takes the third element of the stack to the top of the stack.

=cut

sub CGI::WeT::Modules::ROT {
    my $engine = shift;

    my($e1, $e2, $e3) =
	($engine->content_pop,
	 $engine->content_pop,
	 $engine->content_pop);
    $engine->content_push($e2, $e1, $e3);
    return '';
}

=pod

=item SWAP

This extension swaps the top two elements of the content stack

=cut

sub CGI::WeT::Modules::SWAP {
    my $engine = shift;

    my($e1, $e2) =
	($engine->content_pop,
	 $engine->content_pop);
    $engine->content_push($e1, $e2);
    return '';
}

=pod

=item POP

This extension discards the top of the content stack.

=cut

sub CGI::WeT::Modules::POP {
    my $engine = shift;

    $engine->content_pop;
    return '';
}

=pod

=item IF

This extension will leave either the second or the third element on the
top of the content stack depending on whether or not the top element is
true or false (non-blank or blank).

=cut

sub CGI::WeT::Modules::IF {
    my $engine = shift;

    my($switch) = join("", $engine->render_content);
    my($trueec, $falseec) =
	($engine->content_pop,
	 $engine->content_pop);

    $engine->content_push($switch =~ /^\s*$/ ? $falseec : $trueec);
    return '';
}

=pod

=item QIF

Given three elements on the top of the content stack, it will render the
top element by the second or leave the third depending on whether the top
is true or false (non-blank or blank).

=cut

sub CGI::WeT::Modules::QIF {
    my $engine = shift;

    my($switch) = join("", $engine->render_content);
    my($truec, $falsec) =
	($engine->content_pop,
	 $engine->content_pop);

    $engine->content_push($switch =~ /^\s*$/ 
			  ? $falsec
			  : ([ [ $switch ], '[TEXT]' ], $truec) );
    return '';
}

=pod

=item IFMODULE

Operates the same as B<IF> except the conditional is a list of modules given
as arguments.  For example 

    '[IFMODULE module=NEWS_SUMMARY module=HELP_URL]'

will leave the top of the content stack if and only if both NEWS_SUMMARY and
HELP_URL are available under in CGI::WeT::Modules:: .  Otherwise, it will
leave the next to the top of the content stack on top.  In either case, the
content stack will have one less element afterwards.

=cut

sub CGI::WeT::Modules::IFMODULE {
    my $engine = shift;

    my(@mods) = (($engine->argument('module')), 'IFMODULE');
    my($truec, $falsec) =
	($engine->content_pop,
	 $engine->content_pop);
    my($mod);

    while(@mods) {
	no strict;
	$mod = shift(@mods);
	last unless defined $ { "CGI::WeT::Modules::$mod" };
    }
    $engine->content_push( scalar(@mods) ? $falsec : $truec);
    return '';
}

=pod

=item NAVIGATION

This extension will render the navigation for the particular page.  Several
arguments are available to customize the look.

B<type> - if 'text' then rendering is done with text.  Otherwise, the value is
used to determine the directory in which the graphics images reside.  This
depends on the theme.

B<bullet> - defines a graphical element to prefix the navigational elements
with.  Arguments that help define the image are: bullet_width, bullet_height.

B<align> - if this is 'center' then the navigational element is centered.

B<begin> - defines the initial HTML to use in building the navigation.

B<end> - defines the final HTML to use in building the navigation.

B<top> - if 'yes' will place a link to the top of the site.

B<up> - if 'yes' will place a link to the level above the current level.

B<join> - determins the HTML used between navigational elements.

B<level> - if 'current' only places navigation for the current level.
Otherwise, renders an outline from the top to the current level.

=cut

sub CGI::WeT::Modules::NAVIGATION {
    my $engine = shift;

    my(@output);
    my(@keys);
    my($bt, $et, $bullet, $picdir, $join, $jjoin, $k, $line);
    my($loc, @navcomps, $nextlevel, $mysitemap, $up, $link);

    if($engine->argument('type') eq 'text') {
	if($engine->argument('bullet')) {
	    $bullet = "<img src=\"" .
		$engine->url('@@GRAPHICS@@', $engine->argument('bullet')) .
		    "\" hspace=0 vspace=0 border=0";
	    foreach ('width', 'height') {
		$bullet .= " $_=" . $engine->argument("bullet_$_")
		    if defined $engine->argument("bullet_$_");
	    }

	    $bullet .= " border=0>";
	}
	if(defined $engine->argument('size')) {
	    $bt .= "<font size=" . $engine->argument('size') . ">";
	    $et = "</font>$et";
	}
	$picdir = '';
    } else {
	$picdir = $engine->url('@@GRAPHICS@@/', $engine->argument('type'));
	if(defined $engine->argument('bullet')) {
	    $bullet = "<img src=\"$picdir/" . $engine->argument('bullet') .
		"\" hspace=0 vspace=0";
	    foreach ('width', 'height') {
		$bullet .= " $_=" . $engine->argument("bullet_$_")
		    if defined $engine->argument("bullet_$_");
	    }
	    
	    $bullet .= " border=0>";
	}
    }
    if($engine->argument('align') eq 'center') {
	$bt .= "<center>";
	$et = "</center>$et";
    }
    $bt .= $engine->argument('begin');
    $et = $engine->argument('end') . $et;

    if($engine->argument('type') eq 'text') {
	$jjoin = $engine->argument('join');
    } else {
	if($engine->argument('join') && $engine->argument('join') !~ /[<>]/) {
	    $jjoin = "<img border=0 src=\"$picdir/" .
		$engine->argument('join') .
		    "\"";
	    foreach ('width', 'height', 'align') {
		$bullet .= " $_=" . $engine->argument("join_$_")
		    if defined $engine->argument("join_$_");
	    }
	    $jjoin .= ">";
	} else {
	    $jjoin = $engine->argument('join');
	}
    }

    push(@output, $bt);

    if($engine->argument('top') eq 'yes') {
	if($engine->argument('type') eq 'text') {
	    push(@output, "$bullet<a href=\"", $engine->url('@@TOP@@'),
		 "\">Top</a>");
	} else {
	    push(@output, "$bullet<a href=\"", $engine->url('@@TOP@@'),
		 "\"><img border=0 src=\"$picdir/top",
		 $engine->argument('suffix'), "\"></a>");
	}
	$join = $jjoin;
    }

    if($engine->{'THEME'}->NAVPATH eq 'Top') {
	my $sitemap = $engine->{'THEME'}->SITEMAP;
	foreach ($sitemap->KEYS) {
	    my $line = " $join $bullet<a href=\""
		. $engine->url($sitemap->{$_}->{'location'}) .
		    "\">";
	    
	    if($engine->argument('type') eq 'text') {
		push(@output, "$line$_</a>");
	    } else {
		my $loc = $sitemap->{$_}->{'button'} ||
		    $sitemap->{$_}->{'location'};
		$loc =~ s,/$,,;
		$loc =~ s,\.([^/]*)$,,;
		$loc = $engine->url($loc, $engine->argument('suffix'));
		push(@output, "$line<img border=0 src=\"$loc\" alt=\"$_\"></a>");
	    }
	}
	$join = $jjoin;
    } else {
	my @navcomps = split(/\|/, $engine->{'THEME'}->NAVPATH);
	my $sitemap;
	my $nextlevel;
	my $up;

	if($engine->argument('level') eq 'current') {
	    $sitemap = new CGI::WeT::Theme::Aux::SiteMap;
	    $sitemap->add_node('Top');
	    $sitemap->{'Top'}->{'location'} = '@@TOP@@';
	    $sitemap->submap('Top', $engine->{'THEME'}->SITEMAP);
	    
	    $nextlevel = 'Top';
	    if($engine->argument('type') eq 'text') {
		$up = " $join $bullet<a href=\"" . $engine->url('@@TOP@@')
		    . "\">Up</a>";
	    } else {
		$up = " $join $bullet<a href=\"" . $engine->url('@@TOP@@')
		    . "\"><img border=0 src=\"$picdir/up"
			. $engine->argument('suffix'), "\"></a>";
	    }
	    while(defined $sitemap->submap($nextlevel) && @navcomps > 1) {
		$sitemap = $sitemap->submap($nextlevel);
		$nextlevel = shift @navcomps;
		if($engine->argument('type') eq 'text') {
		    $up = " $join $bullet<a href=\""
			. $engine->url($sitemap->{$nextlevel}->{'location'})
			    . "\">Up</a>";
		} else {
		    $up = " $join $bullet<a href=\"" 
			. $engine->url($sitemap->{$nextlevel}->{'location'})
			    . "\"><img border=0 src=\"$picdir/up"
				. $engine->argument('suffix'), "\"></a>";
		}
	    }
	    
	    if($engine->argument('up') eq 'yes') {
		push(@output, $up);
		$join = $jjoin;
	    }

	    $sitemap = $sitemap->submap($nextlevel);
	    $nextlevel = shift @navcomps;
	    $sitemap = $sitemap->submap($nextlevel);
	    $nextlevel = shift @navcomps;
	}
	if($sitemap) {
	    foreach ($sitemap->KEYS) {
		my $link;
		if($engine->argument('type') eq 'text') {
		    $link = $_;
		} else {
		    my $loc = $sitemap->{$_}->{'button'} ||
			$sitemap->{$_}->{'location'};
		    $loc =~ s,/$,,;
		    $loc =~ s,\.([^/]*)$,,;
		    $loc = $engine->url($loc, $engine->argument('suffix'));
		    $link = "<img border=0 src=\"$loc\" alt=\"$_\">";
		}
		if($nextlevel ne $_ && !@navcomps) {
		    $link = " $join $bullet<a href=\""
			. $engine->url($sitemap->{$_}->{'location'}) .
			    "\">$link</a>";
		} else {
		    $link = " $join $bullet$link";
		}
		push(@output, $link);
		
		$join = $jjoin;
		if($nextlevel eq $_) {
		    push(@output,
			 &doNavigation( $sitemap->submap, $engine, $bullet,
					$engine->argument('indent'),
					$join, $jjoin, @navcomps) );
		}
	    }
	}
    }
    push(@output, $et);
    return @output;
}

sub doNavigation {
    my($sitemap, $engine, $bullet, $indent, $join, $jjoin, @navcomps) = @_;
    my(@output);

    my $nextlevel = shift @navcomps;
    return '' unless $sitemap;
    foreach ($sitemap->KEYS) {
	my $link;
	if($engine->argument('type') eq 'text') {
	    $link = $_;
	} else {
	    my $loc = $sitemap->{$_}->{'button'} ||
		$sitemap->{$_}->{'location'};
	    $loc =~ s,/$,,;
	    $loc =~ s,\.([^/]*)$,,;
	    $loc = $engine->url($loc, $engine->argument('suffix'));
	    $link = "<img border=0 src=\"$loc\" alt=\"$_\">";
	}
	if($nextlevel ne $_ && !@navcomps) {
	    $link = " $join $bullet<a href=\""
		. $engine->url($sitemap->{$_}->{'location'}) .
		    "\">$link</a>";
	} else {
	    $link = " $join $bullet$link";
	}
	push(@output, $link);
	
	$join = $jjoin;
	if($nextlevel eq $_) {
	    push(@output,
		 &doNavigation( $sitemap->submap, $engine, $bullet,
				$indent . $engine->argument('indent'), 
				$join, $jjoin, @navcomps) );
	}
    }
    
    return @output;
}

=pod

=item NAVPATH

This extension renders a path of links from the top of the site to the
current level.  Currently only supports a B<type> of `text.'
Other arguments are:

B<join> - the code to join to elements in the path.

B<ellipses> - the code to indicate absence of intervening levels

B<depth> - the number of levels to include in the path before dropping
elements.

=cut

sub CGI::WeT::Modules::NAVPATH {
    my $engine = shift;

    my(@output);
    my $sitemap = $engine->{'THEME'}->SITEMAP;
    my($join, $ellipses, @path);

    if($engine->argument('type') eq 'text') {
	$join = $engine->argument('join');
	$ellipses= $engine->argument('ellipses') || '...';
    } else {
	$join = "<img border=0 src=\"" .
	    $engine->url('@@GRAPHICS@@', $engine->argument('type'),
			 '/', $engine->argument('join')
			 );
	foreach ('width', 'height', 'align') {
	    $join = " $_=" . $engine->argumment("join_$_")
		if $engine->argument("join_$_");
	}
	$join .= ">";
	$ellipses = "<img border=0 src=\"" .
	    $engine->url('@@GRAPHICS@@', $engine->argument('type'),
			 '/', $engine->argument('ellipses')
			 );
	foreach ('width', 'height', 'align') {
	    $ellipses = " $_=" . $engine->argumment("ellipses_$_")
		if $engine->argument("ellipses_$_");
	}
	$ellipses .= ">";
    }

    @path = split(/\|/, $engine->{'THEME'}->NAVPATH);
    push(@output, "<a href=\"", $engine->url('@@TOP@@'), "\">Top</a>");
    shift @path if $path[0] eq 'Top';
    
    if($engine->argument('depth') < $#path) {
	push(@output, " $join $ellipses ");
	while($#path > $engine->argument('depth')) {
	    $sitemap = $sitemap->submap($path[0]);
	    shift @path;
	}
    }

    while(@path) {
	push(@output, " $join ");
	if($engine->argument('type') eq 'text') {
	    push(@output, "<a href=\"", 
		 $engine->url($sitemap->{$path[0]}->{'location'}),
		 "\">$path[0]</a>");
	}
	$sitemap = $sitemap->submap($path[0]);
	shift @path;
    }
    return @output;
}

=pod

=item THEME_CHOOSER

This extension will place a form on the page allowing the user to choose a
different theme.  Requires a CGI script '/chooser.cgi' in the root of the
site.  The value of B<join> is placed between the selection list and the
submit button.

=cut

sub CGI::WeT::Modules::THEME_CHOOSER {
    my $engine = shift;

    my $theme;
    my $url = $engine->url('/chooser.cgi');

    my(@output) = (
"<form action=\"$url\" method=\"get\">",
'<select name="theme">'
		   );

    my(@themes);
    my(@loaders) = map((m/(.*)::$/), 
		       grep(/::$/, keys %CGI::WeT::Theme::Loader::));

    while(@loaders) {
	push(@themes, 
	     list_themes { "CGI::WeT::Theme::Loader::" . shift(@loaders)} ()
	     );
    }

    my(%selected);
    $selected{$engine->argument('theme') || $engine->{'DEFAULT_THEME'}} = 
	' selected';

    foreach $theme (@themes) {
	push(@output, "<option value=\"$theme\"$selected{$theme}>$theme</option>");
    }

    push(@output,
	 '</select>', $engine->argument('join'),
	 '<input type="submit" value="Change">',
	 '</form>'
	 );
    return @output;
}

1;


