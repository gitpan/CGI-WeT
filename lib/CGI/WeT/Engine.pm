#
# $Id: Engine.pm,v 1.8 1999/03/06 20:07:00 jsmith Exp $
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

package CGI::WeT::Engine;

use strict;
use Carp;
use vars qw($VERSION);
use integer;

$VERSION = '0.6.2';

=pod

=head1 NAME

CGI::WeT::Engine - Theme engine for the CGI::WeT package

=head1 SYNOPSIS

    use CGI::WeT::Engine ();

=head1 DESCRIPTION

This module provides a web site with the ability to provide themes.  It is
designed to work seamlessly with B<mod_perl> but can be made to work without
B<mod_perl> without too much difficulty.  

=head1 NOT USING MOD_PERL

To use this module without B<mod_perl>, a script must be written to handle
all themed page requests.  A sample script might be

    #!/usr/bin/perl

    use CGI::WeT::Engine;
    use CGI::WeT::Theme;
    use CGI::WeT::Modules::Basic;

    my $filename = $ENV{'PATH_TRANSLATED'};
    my $url = $ENV{'PATH_INFO'};

    my($key, $val);

    my $engine = new CGI::WeT::Engine;

    if($inputfile) {

	#
	# get the title and other headers out of the themed page
	#

	open IN, "<$inputfile";

        while(<IN>) {

            last if /^\s*$/;
            next if /^\s*#/;

            chomp;

            if(/^[A-Za-z_]+:/) {
                ($key, $val) = split(/:/,$_,2);
            } else {
                $val = $_;
            }

            $engine->headers_push($key, $val);
        }
	
        #
        # slurp up the rest of the file
        #

        $engine->body_push((<IN>));
        close IN;
    }
    
    $r->print( $engine->render_page );

Apache must then be configured to call the CGI script for all files that
are themed.

=cut
# this is required due to the code, I guess...
=pod
        
=head1

=head1 USING MOD_PERL

To use this module with B<mod_perl>, a handler must be set using the engine
to filter the themed pages.  The following is an example of the changes needed
by the Apache configuration files.

 <Files "*.thtml">
     AddHandler perl-script .thtml
     PerlHandler CGI::WeT::Engine
     PerlSendHeader On
     PerlSetupEnv   On
 </Files>

All required modules must be loaded in at server startup.  No code is loaded
during rendering.  The minimum modules are CGI::WeT::Engine, CGI::WeT::Theme,
and CGI::WeT::Modules::Basic.

=head1 CGI::WeT::Engine API

=over 4

=item $engine = new CGI::WeT::Engine;

Returns a reference to a new rendering engine.  The returned object will
have parsed the arguments to the URL (if GET or POST).  The returned object
will need to be set up before a page can be rendered.

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my ($args, $in, @in, %in, $key, $val, $i, %cookiein, $k);
    my $r = undef;

    my $self = {};

    bless $self, $class;

    $$self{MOD_PERL} = ($ENV{MOD_PERL} =~ /mod_perl\/([.0-9]+)/)[0] || 0;

    $$self{CONTENT} = [ ];

    if($self->{'MOD_PERL'}) {
	$r = Apache->request;

	if($r->method eq 'GET') {
	    $in = $r->args;
	} elsif($r->method eq 'POST') {
	    $r->read($in, $ENV{CONTENT_LENGTH});
	} else {
	    $in = '';
	}
    } else {
	if($ENV{REQUEST_METHOD} eq 'GET') {
	    $in = $ENV{QUERY_STRING};
	} elsif($ENV{REQUEST_METHOD} eq 'POST') {
	    read(STDIN, $in, $ENV{CONTENT_LENGTH});
	} else {
	    $in = '';
	}
    }
    @in = split(/[&;]/,$in);
    foreach $i (0 .. $#in) {
	$in[$i] =~ s/\+/ /g;
	
        ($key, $val) = split(/=/,$in[$i],2);
#
# idiom for multiple entries is taken from Apachi::ASP
#
	
	$key =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
	$val =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
	$val =~ s/[\r\n]+/ /g;
	if(defined $in{$key}) {
	    my $collect = $in{$key};
	    if(ref $collect) {
		push(@{$collect}, $val);
	    } else {
		$in{$key} = [$collect, $val];
	    }
	} else {
	    $in{$key} = $val;
	}
    }
    if($ENV{HTTP_COOKIE}) {
	$in = $ENV{HTTP_COOKIE};
	@in = split(/[&;]/,$in);
	foreach $i (0 .. $#in) {
	    $in[$i] =~ s/\+/ /g;
	    
	    ($key, $val) = split(/=/,$in[$i],2);
	    
	    $key =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
	    $val =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
	    $val =~ s/[\r\n]+/ /g;
	    if(defined $cookiein{$key}) {
		my $collect = $cookiein{$key};
		if(ref $collect) {
		    push(@{$collect}, $val);
		} else {
		    $cookiein{$key} = [$collect, $val];
		}
	    } else {
		$cookiein{$key} = $val;
	    }
	}
	foreach $k (keys %cookiein) {
	    $in{$k} ||= $cookiein{$k};
	}
    }
    
    $self->arguments_push(\%in);

    if($self->{'MOD_PERL'}) {
=pod

If using mod_perl, the following variables may be set using B<PerlSetVar>:

   WeT_SiteName - prefix for page titles to identify the site
   WeT_SiteRoot - prefix for URLs for this site - defaults to '/'
   WeT_DocumentRoot - Defaults to Apache's DocumentRoot
   WeT_Top - location of the top page of the site relative to the SiteRoot
             (this allows splash pages)
   WeT_Email - email of the administrator
   WeT_ProblemsEmail - email for bug reports and other problems
   WeT_DefaultTheme - initial theme people will see
   WeT_UseSSLURLs - (yes or no) - whether to add :SSL and :NOSSL to the
                    end of URLs generated by the engine or not.

Otherwise, the function B<CGI::WeT::site_config> must be defined expecting
a reference to the engine object.  The following members of the object need
to be defined:

   $engine->{'SITENAME'}  -- corresponds to WeT_SiteName
   $engine->{'URLBASES'}->{'URLBASE'}  -- corresponds to WeT_DocumentRoot
   $engine->{'URLBASES'}->{'TOP'}  -- corresponds to WeT_Top
   $engine->{'EMAIL'} -- corresponds to WeT_Email
   $engine->{'PROBLEMS_EMAIL'} -- corresponds to WeT_ProblemsEmail
   $engine->{'DEFAULT_THEME'} -- corresponds to WeT_DefaultTheme
   $engine->{'SSL_URLS'} -- corresponds to WeT_UseSSLURLs

=cut

	# get config from httpd.conf
	$self->{'SITENAME'} = $r->dir_config('WeT_SiteName');
	$self->{'URLBASES'}->{'URLBASE'} = 
	    $r->dir_config('WeT_SiteRoot') || '/';
	$self->{'URLBASES'}->{'TOP'} =
	    $r->dir_config('WeT_Top') || '/';
        $self->{'DOCUMENTROOT'} = $r->dir_config('WeT_DocumentRoot') ||
            $ENV{'DOCUMENT_ROOT'};
	$self->{'EMAIL'} = $r->dir_config('WeT_Email') || $ENV{'SERVER_ADMIN'};
	$self->{'PROBLEMS_EMAIL'} = 
	    $r->dir_config('WeT_ProblemsEmail') || $self->{'EMAIL'};
	$self->{'DEFAULT_THEME'} = $r->dir_config('WeT_DefaultTheme') ||
            'plain';
        $self->{'SSL_URLS'} = ($r->dir_config('WeT_UseSSLURLs') eq 'yes');
        foreach (map((m/(.*)::$/),
                 grep(!/^[A-Z]*$/ && /^[A-Z]/, keys %CGI::WeT::Modules::))) {
            no strict;
            if(defined & { "CGI::WeT::Modules::$_\::initialize" }) {
                & { "CGI::WeT::Modules::$_\::initialize" } ($self, $r);
            }
        }
    } else {
	# get config from subroutine
	no strict;
        if(defined CGI::WeT::site_config) {
    	    &CGI::WeT::site_config($self);
        } else {
            $self->{'URLBASES'}->{'URLBASE'} = '/';
            $self->{'URLBASES'}->{'TOP'} = '/';
            $self->{'DOCUMENTROOT'} = $ENV{'DOCUMENT_ROOT'};
            $self->{'EMAIL'} = $ENV{'SERVER_ADMIN'};
            $self->{'PROBLEMS_EMAIL'} = $self->{'EMAIL'};
            $self->{'DEFAULT_THEME'} = 'plain';
        }
    }

    if($ENV{MOD_PERL} && $r->uri =~ /^([^\?]*)/) { 
	$self->{'URI'} = $1;
    } elsif($ENV{'REQUEST_URI'} =~ /^([^\?]*)/) {
	$self->{'URI'} = $1;
    } else {
	$self->{'URI'} = '/';
    }

    return $self;
}

=pod

=item $engine->content_pop

This function returns the item on the top of the content
stack.  Used primarily in the rendering code and the B<CGI::WeT::Modules>
extensions to the engine.

=cut

sub content_pop {
    my $self = shift;

    return pop @{ $$self{CONTENT} };
}

=pod

=item $engine->content_push(B<array ref>)

This function pushes the B<array ref>erence onto the top of the content
stack.  Used primarily in the rendering code and the B<CGI::WeT::Modules>
extensions to the engine.

=cut

sub content_push {
    my $self = shift;

    push @{ $$self{CONTENT} }, @_;
}

=pod

=item $engine->content_peek

This function returns a reference to the item on the top of the stack without
removing it.  Used primarily in the rendering code and the B<CGI::WeT::Modules>
extensions to the engine.

=cut

sub content_peek {
    my $self = shift;

    return ${ $$self{CONTENT} }[$#{ $$self{CONTENT} }];
}

=pod

=item $engine->arguments_pop

This function returns the item on the top of the argument stack.
Used primarily in the rendering code and the B<CGI::WeT::Modules>
extensions to the engine.  Caveat coder.

=cut

sub arguments_pop {
    my $self = shift;

    return pop @{ $$self{ARGUMENTS} };
}

=pod

=item $engine->arguments_push(B<hash ref>)

This function pushes the B<hash ref>erence onto the top of the argument
stack.
Used primarily in the rendering code and the B<CGI::WeT::Modules>
extensions to the engine.  Caveat coder.

=cut

sub arguments_push {
    my $self = shift;

    push @{ $$self{ARGUMENTS} }, @_;
}

=pod

=item $engine->argument(B<key>)

This function descends the argument stack looking for a definition of
B<key>.  If one is found, it is cached at the top of the stack and returned.
Use this function to retrieve values passed through a GET or POST.  Cookies
may also be retrieved through this method but will be overridden by any
definitions in the GET or POST data.

The calling context determines if the function returns an array or a scalar.
This is only significant if the B<key> appeared multiple times in the cookie,
GET, or POST data.

=cut

sub argument {
    my $self = shift;
    my $arg = shift;
    my ($i, $n);

    if(defined $$self{ARGUMENTS}) {
        $i = scalar(@{ $$self{ARGUMENTS} });
        $n = $i-1;  # points to the top of the stack where we cache the value
        while($i) {
            $i--;
            if(exists $$self{ARGUMENTS}->[$i]->{$arg}) {
                $$self{ARGUMENTS}->[$n]->{$arg} ||=
                    $$self{ARGUMENTS}->[$i]->{$arg};
		if(ref $$self{ARGUMENTS}->[$i]->{$arg}) {
		    return(wantarray 
			   ? @ { $$self{ARGUMENTS}->[$i]->{$arg} }
			   : join(" ", @ { $$self{ARGUMENTS}->[$i]->{$arg} })
			   );
		} else {
		    return(wantarray
			   ? ( $$self{ARGUMENTS}->[$i]->{$arg} )
			   : $$self{ARGUMENTS}->[$i]->{$arg}
			   );
		}
            }
        }
    }
    return undef;
}

=pod

=item $engine->headers_push(B<key> => B<value>, ...)

This function will place B<value> associated with B<key> in the header
hash.  Multiple values are placed in arrays similar to the arguments.
Several B<key>s are meaningful to the rendering code:

B<Title> - Denotes the page title.  This is placed in the document head.

B<Type> - Document type.  This is used to determine which layout to use in a
theme.  The first is highest priority.  The `DEFAULT' type is implied as the
lowest priority layout.

B<Author>, B<Keywords>, B<Date> - These three are placed verbatim in META
tags in the header.  Useful information for search engines.

=cut

sub headers_push {
    my $self = shift;
    my $k;
    my $v;

    $$self{HEADERS} ||= { };

    while (scalar(@_)) {
        $k = shift;
	$v = shift;
	if(defined $$self{HEADERS}->{$k}) {
	    my $collect = $$self{HEADERS}->{$k};
	    if(ref $collect) {
		push(@ { $collect }, $v);
	    } else {
		$$self{HEADERS}->{$k} = [$collect, $v];
	    }
	} else {
	    $$self{HEADERS} -> {$k} = $v;
	}
    }
}

=pod

=item $engine->header(B<key>)

This function retrieves the values associated with B<key>.
The calling context determines if the function returns an array or a scalar.
This is only significant if the B<key> appeared in multiple calls to
B<headers_push>.

=cut

sub header {
    my $self = shift;
    my $arg = shift;

    if(exists $$self{HEADERS}->{$arg}) {
	if(ref $$self{HEADERS}->{$arg}) {
	    return(wantarray 
		   ? @ { $$self{HEADERS}->{$arg} }
		   : join(" ", @ { $$self{HEADERS}->{$arg} })
		   );
	} else {
	    return(wantarray
		   ? ( $$self{HEADERS}->{$arg} )
		   : $$self{HEADERS}->{$arg}
		   );
	}
    }
    return undef;
}

=pod

=item $engine->body_push(B<array>)

This function places B<array> at the end of the body content caching it for
later use by the rendering code.  Text placed in the body cannot be
removed by a provided method.

=cut

sub body_push {
    my $self = shift;

    push @{ $$self{BODY} }, @_;
}

=pod

=item $engine->url(B<array>)

This function forms a string from B<array> prefixing it with the base URL
for the themed site.  Any strings of the form B<@@var@@> are interpolated
from a hash of base URLs.  This provides for locations based on the theme
or site configuration.  Multiple `/'s are collapsed.  This function will
not be able to return theme dependent URLs except during the actual rendering
of a page.

=cut

sub url {
    my $self = shift;
    my $url = join("", $self->{'URLBASES'}->{'URLBASE'}, @_);

    my(@subs) = ($url =~ m/\@\@(.*?)\@\@/g);

    foreach (@subs) {
	if(defined $self->{'THEME'}->{'URLBASES'}->{$_}) {
	    $url =~ s{\@\@$_\@\@}{$self->{'THEME'}->{'URLBASES'}->{$_}}g;
	} else {
	    $url =~ s{\@\@$_\@\@}{$self->{'URLBASES'}->{$_}}g;
	}
    }
    $url =~ s!//!/!g;

    if($self->{'SSL_URLS'}) {
	if($url =~ /\.private\./ || $url =~ /\.form\./) {
	    $url .= ":SSL";
	} else {
	    $url .= ":NOSSL";
	}
    }

    return $url;
}

=pod

=item $engine->filename(B<URL>)

This function will return the location of B<URL> in the filesystem.  This
will use Apache's URl->filename translation code if running under mod_perl.
Otherwise, tacks the document root on the beginning.

=cut

sub filename {
    my $engine = shift;
    my $url = join("", @_);

    $url =~ s/;//g;

    if($engine->{'MOD_PERL'}) {
	my $r = Apache->request;
	my $subr = $r->lookup_uri($url);
	return $subr->filename;
    } else {
	my $filename = $engine->{'DOCUMENTROOT'} . "/" . $url;
	$filename =~ s,//,/,g;
	return $filename;
    }
}

=pod

=item $engine->render_content

This function is the main workhorse returning an array resulting from rendering
the top of the content stack.  Used primarily in the rendering code and the 
B<CGI::WeT::Modules> extensions to the engine.  Caveat coder.

=cut

sub render_content {
    my $self = shift;

    use integer;

    my $layout = $self->content_pop;
    my(@output);
    my($position) = (0);
    my($args, $key, $val, $object);

    return () if !defined $layout;

    while($position < scalar(@$layout)) {
	if(ref($layout->[$position])) {
            $self->content_push($layout->[$position]);
        } else {
            if($layout->[$position] =~ /^\[([A-Z_]+)\s*(.*)\]$/) {
                $object = $1;
                $args = { };
                foreach (split(/\s+/, $2)) {
                    ($key, $val) = split(/=/, $_, 2);
                    $val =~ s/%(..)/pack("c", hex($1))/ge;
		    if(defined $$args{$key}) {
			my $collect = $$args{$key};
			if(ref $collect) {
			    push(@ { $collect}, $val);
			} else {
			    $$args{$key} = [$collect, $val];
			}
		    } else {
			$$args{$key} = $val;
		    }
                }
                $self->arguments_push($args);
		no strict;
                if(defined $self->{'THEME'}->page_type($object)) {
		    $self->content_push($self->{'THEME'}->page_type($object)
					->LAYOUT);
                    push(@output, $self->render_content);
                } elsif(defined & { "CGI::WeT::Modules::$object" }) {
                    push(@output, & { "CGI::WeT::Modules::$object" }($self));
                }
		$self->arguments_pop;
            } else {
                push(@output, $layout->[$position]);
            }
        }
	$position++;
    }
    return @output;
}

=pod

=item $engine->render_page([B<theme>])

This function returns the rendered page constructed with the object using
B<theme> if supplied.  Otherwise the argument stack is consulted to determine
which theme to use.  If B<theme> is supplied, it must be an object returned
by B<new CGI::WeT::Theme> or a derived class of B<CGI::WeT::Theme>.

=cut

sub render_page {
    my $self = shift;
    $self->{'THEME'} = shift;   # will be undef if no theme specified...
    my(@output);
    my($theme, $layout, $css);

    push(@output, "<html>", "<head>");
    push(@output,
         map("<meta name=\"$_\" content=\"" . scalar($self->header($_)) 
	     . "\">",
             grep(defined $$self{HEADERS}->{$_},
                  'Author', 'Keywords', 'Date'
                  )
             )
         );
    push(@output, "<meta name=\"Generator\" content=\"CGI::WeT $CGI::WeT::Engine::VERSION\">");
    push(@output, "<meta name=\"Theme\" content=\"", 
	 $self->argument('theme'),
	 "\">");

    push(@output, "<title>", "$$self{SITENAME} - ", 
	 scalar($self->header('Title')),
         "</title>");

    $self->{'THEME'} ||= new CGI::WeT::Theme($self->argument('theme'))
	|| new CGI::WeT::Theme($self->{'DEFAULT_THEME'});

    $layout = $self->{'THEME'}->page_type(($self->header('Type')), 'DEFAULT');

    if($layout->has_css) {
	push(@output, "<style type=\"text/css\">", "<!-- ");
	push(@output, @ { $layout->CSS });
	push(@output, " -->","</style>", "</head>");
    }
    if(defined $layout->BODY) { 
	my($bodyinfo) = $layout->BODY;
	push(@output, "<body");
	push(@output, " background=\"$bodyinfo->{'background'}\"")
	    if exists $bodyinfo->{'background'};
	foreach ('bgcolor', 'text', 'link', 'vlink', 'alink') {
	    push(@output, " $_=\"#$bodyinfo->{$_}\"")
		if exists $bodyinfo->{$_};
	}
	push(@output, ">");
    } else {
	push(@output, "<body>");
    }

    $self->content_push($layout->LAYOUT);
    push(@output, $self->render_content);
    push(@output, "</body>","</html>");
    return @output;
}

sub handler {
    my $r = shift;
    my $filename = $r->filename;
    my $engine = new CGI::WeT::Engine;
    my ($key, $val);

    if(-e $r->finfo) {
        open IN, "<$filename";
        while(<IN>) {
            last if /^\s*$/;
            next if /^\s*#/;
            chomp;
            if(/^[A-Za-z_]+:/) {
                ($key, $val) = split(/:\s*/,$_,2);
            } else {
                $val = $_;
            }
            $engine->headers_push($key, $val);
        }

        #
        # slurp up the rest of the file
        #
        $engine->body_push((<IN>));
        close IN;
    }

    $r->send_cgi_header(<<EOF);
Content-type: text/html

EOF

    $r->print( $engine->render_page );
}

1;

=pod

=head1 SEE ALSO

perl(1),
CGI::WeT(3),
CGI::WeT::Theme(3),
CGI::WeT::Modules(3),

CGI::WeT notes at C<http://people.physics.tamu.edu/jsmith/wet-perls/>

=head1 AUTHORS

 Written by James G. Smith.
 Copyright (C) 1999.  Released under the GNU General Public License v. 2.

=cut
