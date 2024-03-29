#
# $Id: Engine.pm,v 1.44 1999/11/19 05:41:18 jsmith Exp $
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

package CGI::WeT::Engine;

use strict;
use Carp;
use vars qw(@ISA);
use integer;
#use Apache::Constants;
use IO::File ();
use CGI::WeT ':cgi-lib :standard';

@ISA = (qw/CGI/);

#( $VERSION ) = '$Revision: 1.44 $ ' =~ /\$Revision:\s+([^\s]+)/;

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
            next if /^\s*\#/;

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

        $engine->print((<IN>));
        close IN;
    }
    
    # page is rendered when $engine is destroyed...

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

=head1 USING TIED HANDLES

CGI::WeT::Engine now supports tied handles.  This makes themeing of older
code much easier:

    use CGI::WeT;
    tie *STDOUT, 'CGI::WeT::Engine';

    print "Title: <title of page>\nAuthor: A. U. Thor\n\n";

    .
    .  Old script here printing to STDOUT
    .

    untie *STDOUT;

The resulting page will have the scripts output as the body.  When using this
method, do not use the CGI::start_html function -- this is taken care of by
the CGI::WeT::Engine code.

=head1 CGI::WeT::Engine API

=over 4

=item $engine = new CGI::WeT::Engine;

Returns a reference to a new rendering engine.  The returned object will
have parsed the arguments to the URL (if GET or POST).  The returned object
will need to be set up before a page can be rendered.

When the object returned by B<new> is destroyed, the page is rendered to
STDOUT.

=cut

sub _new {
  my $this = shift;
  my $class = ref($this) || $this;
  my ($args,$in, %in, $key, $val, $i, %cookiein, $k);
  my $r = undef;

  my $self = { };

  bless $self, $class;

  $self->{'MOD_PERL'} = ($ENV{MOD_PERL} =~ /mod_perl\/([.0-9]+)/)[0] || 0;

  $self->{'CONTENT'} = [ ];

  if($ENV{'HTTP_COOKIE'}) {
    foreach $i (split(/[&;]/,$ENV{'HTTP_COOKIE'})) {
      $i =~ s/\+/ /g;

      ($key, $val) = split(/=/,$i,2);

      $key =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
      $val =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
      $val =~ s/\r+//g;
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
    foreach $k (keys %in) {
      $in{$k} ||= $in{$k};
    }
  }
 
  $self->arguments_push(\%in);

  if($self->{'MOD_PERL'}) {
    # get config from httpd.conf
    $r = Apache->request;
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
    $self->{'DEFAULT_THEME'} = $ENV{'WET_THEME'} ||
      $r->dir_config('WeT_DefaultTheme') ||
        'plain';
    $self->{'SSL_URLS'} = $r->dir_config('WeT_UseSSLURLs');
    $self->{'AC'} = $r->dir_config('WeT_AnonymousCoward');
    foreach (map((m/(.*)::$/),
                 grep(!/^[A-Z_]*$/ && /^[A-Z]/,
                      keys %CGI::WeT::Modules::))) {
      no strict;
      if(defined & { "CGI::WeT::Modules::$_\::initialize" }) {
        & { "CGI::WeT::Modules::$_\::initialize" } ($self, $r);
      }
    }
  } else {
    # get config from subroutine
    no strict;
    if(defined &CGI::WeT::site_config) {
      &CGI::WeT::site_config($self);
    } else {
      $self->{'URLBASES'}->{'URLBASE'} = '/';
      $self->{'URLBASES'}->{'TOP'} = '/';
      $self->{'DOCUMENTROOT'} = $ENV{'DOCUMENT_ROOT'};
      $self->{'EMAIL'} = $ENV{'SERVER_ADMIN'};
      $self->{'PROBLEMS_EMAIL'} = $self->{'EMAIL'};
      $self->{'DEFAULT_THEME'} = $ENV{'WET_THEME'} || 'plain';
      $self->{'AC'} = 'Anonymous Coward';
    }
  }
 
  if   ($ENV{'MOD_PERL'} && $r->uri =~ /^([^\?]*)/) { $self->{'URI'} = $1;  }
  elsif($ENV{'REQUEST_URI'} =~ /^([^\?]*)/)         { $self->{'URI'} = $1;  }
  else                                              { $self->{'URI'} = '/'; }

  if($self->{'MOD_PERL'}) {
    #$r = Apache->request;

    #
    # take care of Apache::Filter detection here...
    #
    if(defined &Apache::filter_input) {
      no strict 'subs';
      $self->{'FILTERED'} = $Apache::Filter::VERSION || 1;
      $self->{'STDOUT'} = tied *STDOUT;
    } else {
      $self->{'FILTERED'} = 0;
      $self->{'STDOUT'} = $r;
    }
  }
 
  $self->{'doing_headers'} = 0;

  return $self;
}

sub new {
  my $this = shift;
  my ($args,$in, %in, $key, $val, $i, %cookiein, $k);
  my $r = undef;
  
  my $self = _new($this, @_);
  
  if($self->{'MOD_PERL'}) {
    $r = Apache->request;
  }    
#    if   ($r->method eq 'GET' ) { $in = $r->args;                      }
#    elsif($r->method eq 'POST') { $r->read($in, $ENV{CONTENT_LENGTH}); }
#    else                        { $in = '';                            }
#  } else {
#    if($ENV{REQUEST_METHOD} eq 'GET')     
#      { $in = $ENV{QUERY_STRING}; }
#    elsif($ENV{REQUEST_METHOD} eq 'POST') 
#      { read(STDIN, $in, $ENV{CONTENT_LENGTH}); }
#    else 
#      { $in = ''; }
#  }

#  foreach $i (split(/[&;]/,$in)) {
#    $i =~ s/\+/ /g;
#    
#    ($key, $val) = split(/=/,$i,2);
#    #
#    # idiom for multiple entries is taken from Apachi::ASP
#    #
#    
#    $key =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
#    $val =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
#    $val =~ s/\r+//g;
#    if(defined $in{$key}) {
#      my $collect = $in{$key};
#      if(ref $collect) {
#	push(@{$collect}, $val);
#      } else {
# 	$in{$key} = [$collect, $val];
#      }
#    } else {
#      $in{$key} = $val;
#    }
#  }
#
#  $self->arguments_push(\%in);

  return $self;
}

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
                      this can be overridden with the environment variable
                      `WET_THEME'
   WeT_UseSSLURLs - whether to add :SSL and :NOSSL to the
                    end of URLs generated by the engine or not. (This
                    is considered true if defined.)  This is still
                    experimental and will most likely break graphical
                    navigation.
   WeT_AnonymousCoward - in a bow to slashdot.org, this is what the site
                         names anonymous contributors.  This is not
                         retroactive (yet).

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
   $engine->{'AC'} -- corresponds tp WeT_AnonymousCoward
=cut
# ' for Emacs
# ` for Emacs

sub DESTROY {
  my $engine = shift;
  my $r;

  return if $engine->{'INTERNAL_USE_ONLY'};

  if($engine->{'doing_headers'}) {
    $engine->print("\n\n");
  }
     
  if($engine->{'MOD_PERL'} ) {
    $r = Apache->request;
    my $fh = $engine->{'STDOUT'};
    
#    $r->content_type('text/html');
    
#    $r->cgi_headers_out unless $engine->{'FILTERED'};
    
    $fh->print($engine->render_page);
  } else {
#    print "Content-type: text/html\n\n";
    print $engine->render_page;
  }
}

=pod

=item $engine->internal_use_only

This function will mark the $engine object as being for internal use only
(hence its name).  That is, it will not output a page to output upon
destruction.  Returns the previous value.  If an argument is present, the
internal flag is set to that value.

This function is valuable if a CGI script decides it needs to redirect instead
of outputing HTML.  Calling this function will disable automatic HTML output.

=cut

sub internal_use_only {
  my $engine = shift;
  my $v = $engine->{'INTERNAL_USE_ONLY'};
 
  $engine->{'INTERNAL_USE_ONLY'} = scalar(@_) ? shift : 1;
  return $v;
}

=pod

=item $engine->content_pop

This function returns the item on the top of the content
stack.  Used primarily in the rendering code and the B<CGI::WeT::Modules>
extensions to the engine.  An optional argument specifies how many elements
to pop.

=cut

sub content_pop {
  my $self = shift;
  my $num = shift || 1;
  
  $num = 
    ($num > scalar(@{ $self->{'CONTENT'} })) ? 
      scalar(@{ $self->{'CONTENT'} }) : 
	$num;
  
  return splice(@{ $self->{'CONTENT'} }, -$num);
}

=pod

=item $engine->content_push(B<array ref>)

This function pushes the B<array ref>erence onto the top of the content
stack.  Used primarily in the rendering code and the B<CGI::WeT::Modules>
extensions to the engine.

=cut

sub content_push {
  my $self = shift;

  push @{ $self->{'CONTENT'} }, @_;
}

=pod

=item $engine->content_peek

This function returns a reference to the item on the top of the stack without
removing it.  Used primarily in the rendering code and the B<CGI::WeT::Modules>
extensions to the engine.

=cut

sub content_peek {
    my $self = shift;

    return $self->{'CONTENT'}->[-1];
}

=pod

=item $engine->arguments_pop

This function returns the item on the top of the argument stack.
Used primarily in the rendering code and the B<CGI::WeT::Modules>
extensions to the engine.  Caveat coder.

=cut

sub arguments_pop {
    my $self = shift;

    return pop @{ $self->{'ARGUMENTS'} };
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

  push @{ $self->{'ARGUMENTS'} }, @_;
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

  if(defined $self->{'ARGUMENTS'}) {
    $i = scalar(@{ $self->{'ARGUMENTS'} });
    while($i) {
      $i--;
      if(exists $self->{'ARGUMENTS'}->[$i]->{$arg}) {
	$self->{'ARGUMENTS'}->[-1]->{$arg} ||=
	  $self->{'ARGUMENTS'}->[$i]->{$arg};
	if(ref $self->{'ARGUMENTS'}->[-1]->{$arg}) {
	  return(wantarray 
		 ? @ { $self->{'ARGUMENTS'}->[-1]->{$arg} }
		 : join(" ", @ { $self->{'ARGUMENTS'}->[-1]->{$arg} })
		);
	} else {
	  return(wantarray
		 ? ( $self->{'ARGUMENTS'}->[-1]->{$arg} )
		 : $self->{'ARGUMENTS'}->[-1]->{$arg}
		);
	}
      }
    }
  }
  #print STDERR "Couldn't find $arg\n";
  #print STDERR "Param -> ", param('-name' => $arg), "\n";
  return $self->{QUERY}->param('-name' => $arg) if defined $self->{QUERY};
  return undef;
}

sub set_query_object {
  my $self = shift;

  $self->{QUERY} = shift;
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
# ' for Emacs
# ` for Emacs

sub headers_push {
  my $self = shift;
  my $k;
  my $v;

  $self->{'HEADERS'} ||= { };

  while (scalar(@_)) {
    $k = shift;
    $v = shift;
    if(defined $self->{'HEADERS'}->{$k}) {
      my $collect = $self->{'HEADERS'}->{$k};
      if(ref $collect) {
	push(@ { $collect }, $v);
      } else {
	$self->{'HEADERS'}->{$k} = [$collect, $v];
      }
    } else {
      $self->{'HEADERS'} -> {$k} = $v;
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
  
  if(exists $self->{'HEADERS'}->{$arg}) {
    if(ref $self->{'HEADERS'}->{$arg}) {
      return(wantarray 
	     ? @ { $self->{'HEADERS'}->{$arg} }
	     : join(" ", @ { $self->{'HEADERS'}->{$arg} })
	    );
    } else {
      return(wantarray
	     ? ( $self->{'HEADERS'}->{$arg} )
	     : $self->{'HEADERS'}->{$arg}
	    );
    }
  }
  return undef;
}

=pod

=item $engine->print(B<array>)

This function places B<array> at the end of the body content caching it for
later use by the rendering code.  Text placed in the body cannot be
removed by a provided method.

=cut

sub print {
  my $self = shift;
 
    if($self->{'doing_headers'}) {
        $self->{'buffer'} .= join($,, @_);
        if($self->{'buffer'} =~ /\n\s*\n/s) { 
            my($headers, $body) = split(/\n\s*\n/, $self->{'buffer'},2);
            foreach my $l (split(/\n/, $headers)) {
                $self->headers_push(split(/\s*:\s*/, $l, 2));
            }
            push @{ $self->{'BODY'} }, $body;
            delete $self->{'buffer'};
            $self->{'doing_headers'} = 0;
        }
    } else { 
        push @{ $self->{'BODY'} }, @_;
    }
}       

sub PRINT {
    my $self = shift;

    $self->print(@_);
    print STDERR "Printing from CGI::WeT::Engine\n";
}

=pod

=item $engine->url(B<array>)

This function forms a string from B<array> prefixing it with the base URL
for the themed site.  Any strings of the form B<@@var@@> are interpolated
from a hash of base URLs.  This provides for locations based on the theme
or site configuration.  Multiple `/'s are collapsed.  This function will
not be able to return theme dependent URLs except during the actual rendering
of a page.

If the url built from B<array> begins with `/', then the link is absolute with
respect to the top of the site.  Otherwise, it is relative to the page being
produced.

If this function is called without arguments, it will return the URI of the
current request.

=cut
# ' for Emacs
# ` for Emacs


sub url {
  my $self = shift;

  unless(@_) {
    if($self->{'MOD_PERL'}) {
      my $r = Apache->request;
      return $r->uri();
    } else {
      return $ENV{'SCRIPT_URL'};
    }
  }
  
  my $url = join("", @_);
  
  my(@subs) = ($url =~ m/\@\@(.*?)\@\@/g);
  
  foreach (@subs) {
    if(defined $self->{'THEME'}->{'URLBASES'}->{$_}) {
      $url =~ s{\@\@$_\@\@}{$self->{'THEME'}->{'URLBASES'}->{$_}}g;
    } else {
      $url =~ s{\@\@$_\@\@}{$self->{'URLBASES'}->{$_}}g;
    }
  }
  
  if($url =~ /^\//) {
    $url = $self->{'URLBASES'}->{'URLBASE'} . "/$url";
  }
  
  1 while($url =~ s!//!/!g);
  
  if($self->{'SSL_URLS'}) {
    $url =~ s/:(NO)SSL//g;
    if($ENV{'SSL_PROTOCOL'}) {
      if($url !~ /\.private\./ && $url !~ /\.form\./) {
	$url .= ":NOSSL";
      }
    } else {
      if($url =~ /\.private\./ || $url =~ /\.form\./) {
	$url .= ":SSL";
      }
    }
  }
  
  return $url;
}

=pod

=item $engine->filename(B<URL>)

This function will return the location of B<URL> in the filesystem.  This
will use Apache's URl->filename translation code if running under mod_perl.
Otherwise, tacks the document root on the beginning.  If no arguments are
passed, it will return the filename of the current page.

=cut
# ` for Emacs
# ' for Emacs

sub filename {
  my $engine = shift;
  my $url;
  if(@_) {
    $url = join("", @_);
    $url =~ s/;//g;
    $url =~ s/:(NO)SSL$// if($engine->{'SSL_URLS'});
  } else {
    $url = undef;
  }
  
  if($engine->{'MOD_PERL'}) {
    my $r = Apache->request;
    if(defined $url) {
      my $subr = $r->lookup_uri($url);
      return $subr->filename;
    } else {
      return $r->filename();
    }
  } else {
    if(defined $url) {
      my $filename = $engine->{'DOCUMENTROOT'} . "/" . $url;
      $filename =~ s,//,/,g;
      return $filename;
    } else {
      return $ENV{'SCRIPT_FILENAME'};
    }
  }
}

=pod

=item $engine->smarttext(B<array>)

This function will accept the B<array> of plain text and return a string
of HTML formatted text.

HTML character entities are preserved.  Also, &star; and &under; are
translated to `*' and `_' respectively.  Paragraphs beginning with whitespace
are quoted as preformatted text.  The ampersand, greater-than and less-than
are translated to character entities.  Therefore, no HTML may be included in
the input text.  Text may be _underlined_ or made *bold*.

=cut

# ' for Emacs
# ` for Emacs

# following is based on _The Perl Cookbook_

sub _smarttext_render_p {
  my($p) = shift;
  
  $p =~ s/%/%25/gs;
  $p =~ s/&(.*?);/%%$1%%/gs;
  $p =~ s/&/&amp;/gs;
  $p =~ s/</&lt;/gs;
  $p =~ s/>/&gt;/gs;
  $p =~ s/%%(.*?)%%/&$1;/gs;
  $p =~ s/%25/%/gs;
  
  $p =~ tr/\n/ /;
  $p =~ s{^(&gt;.*)}  {$1<br>}gms;        # quoted text
  $p =~   s{&lt;URL:\s*(.*?)&gt;}   {<a href="$1">$1</a>}gsi 
    ||   # these are for URLs
      s{((http|ftp|https):\S+)} {<a href="$1">$1</a>}gs; 
  $p =~ s{\*(.*?)\*} {<strong>$1</strong>}gs;
  $p =~ s{\b_(.*?)\_\b} {<i>$1</i>}gs;
  $p =~ s{&star;}            {*}gsi;
  $p =~ s{&under;}           {_}gsi;
  $p = "<p>$p</p>";
  
  return $p;
}

sub smarttext {
  my $engine = shift;
  chomp(@_);
  my $text = join(" \n", @_);
  my (@text) = split(/\n/, $text);
  
  my $paragraph;
  my $output;
  my $line;
  my $p;
  
  while(@text) {
    $line = shift @text;
    $line =~ s/\r//gs;
    if($line =~ /^\s*$/ && $p) {
      $output .= &_smarttext_render_p($p);
      $p = '';
    } elsif($line =~ /^\s/) {
      $line =~ s{(.*)$ } {<pre>\n$1</pre>\n}sx;
      if($p) {
	$output .= &_smarttext_render_p($p);
	$p = '';
      }
      $output .= $line; 
    } else {
      $p .= "$line";
    }	
  }
  
  # do last paragraph...
  $output .= &_smarttext_render_p($p);
  
  return wantarray ? split(/\n/, $output) : $output;
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
	  my $pt = $self->{'THEME'}->page_type($object);
	  $self->content_push($pt->LAYOUT || [ '' ]);
	  push(@output, $self->render_content);
	  if($pt->SCRIPTS) {
	    my $s;
	    foreach $s (keys % { $pt->SCRIPTS }) {
	      if($self->argument("\L$s") ne 'no') {
		$self->{'SCRIPTS'}->{$s}->{$object} =
		  $pt->SCRIPTS->{$s};
	      }
	    }
	  }
	} elsif(defined & { "CGI::WeT::Modules::$object" }) {
	  push(@output, & { "CGI::WeT::Modules::$object" }($self));
	  if(defined & { "CGI::WeT::Scripts::$object" }) {
	    my $sk = & { "CGI::WeT::Scripts::$object" }($self);
	    foreach $s (keys %$sk) {
	      if($self->argument("\L$s") ne 'no') {
		$self->{'SCRIPTS'}->{$s}->{$object} =
		  $sk->{$s};
	      }
	    }
	  }
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
  my(@output, @head);
  my($theme, $layout, $css);

  my $version = $CGI::WeT::VERSION || $CGI::WeT::Engine::VERSION;
  
  push(@head,
       map("<meta name=\"$_\" content=\"" . scalar($self->header($_)) 
	   . "\">\n",
	   grep(defined $$self{HEADERS}->{$_},
		'Author', 'Keywords', 'Date'
	       )
	  )
      );
  push(@head, "<meta name=\"Generator\" content=\"CGI::WeT $version\">\n");
  push(@head, "<meta name=\"Theme\" content=\"", 
       $self->argument('theme'),
       "\">\n");
  
  push(@head, "<title>", "$$self{SITENAME} - ", 
       scalar($self->header('Title')),
       "</title>\n");
  
  $self->{'THEME'} ||= new CGI::WeT::Theme($self->argument('theme'))
    || new CGI::WeT::Theme($self->{'DEFAULT_THEME'});
  
  $layout = $self->{'THEME'}->page_type(($self->header('Type')), 'DEFAULT');
  
  if($layout->has_css) {
    push(@head, "<style type=\"text/css\">", "<!-- ");
    push(@head, @ { $layout->CSS });
    push(@head, " -->","</style>");
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
  my $sk;
  foreach $sk (keys % { $self->{'SCRIPTS'} }) {
    if($self->{'SCRIPTS'}->{$sk}) {
      push(@head, "<script language=\"$sk\">", "<!--\n");
      my $jk;
      foreach $jk (keys % { $self->{'SCRIPTS'}->{$sk} }) {
	push(@head, "// for $jk\n",
	     join("\n", @ { $self->{'SCRIPTS'}->{$sk}->{$jk} }));
      }
      push(@head, "\n// -->", "</script>");
    }
  }

  return ("<html>\n", "<head>\n", @head, "\n</head>\n", @output,
          $self->end_html);
}

sub handler {
  no strict "subs";
  my $engine = new CGI::WeT::Engine;
  my($r, $fh, $res);
  
  if($engine->{'FILTERED'}) {
    $r = $_[0];
    ($fh, $res) = Apache->filter_input();
  } else {
    $r = shift;
    $fh = new IO::File;  
    my $filename = $r->filename;
    if($fh->open("<$filename")) {
      $res = Apache::Constants::OK;
    } else {
      $res = Apache::Constants::NOT_FOUND;
    }
  }
  
  unless($res == Apache::Constants::OK) {
    $engine->internal_use_only(); # don't output the html
    return $res; 
  }
  
  my ($key, $val);
  
  while(<$fh>) {
    last if /^\s*$/;
    next if /^\s*\#/;
    chomp;
    if(/^[A-Za-z_]+:/) {
      ($key, $val) = split(/:\s*/,$_,2);
    } else {
      $val = $_;
    }
    $engine->headers_push($key, $val);
  }
  
  _handler($fh, $engine);

  $r->content_type('text/html');
  
  return Apache::Constants::OK unless $r->is_initial_req;
  return Apache::Constants::DONE;
  # rendering done on $engine destruction
}

#
# _handler is here to handle any translations to be done on the contents
# of the html...  nothing too great so far
#
sub _handler {
  my($in, $out) = @_;
  
  #
  # slurp up the rest of the file
  #
  #$out->print($_) while(<$in>);
  $out->print(<$in>);
}
    
1;

=pod

=head1 SEE ALSO

perl(1),
CGI(3),
CGI::WeT(3),
CGI::WeT::Theme(3),
CGI::WeT::Modules(3),

CGI::WeT notes at C<http://www.jamesmith.com/cgi-wet/>

=head1 AUTHORS

 Written by James G. Smith.
 Copyright (C) 1999.  Released under the Artistic License.

=cut
