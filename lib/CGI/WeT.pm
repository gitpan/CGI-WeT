#
# $Id: WeT.pm,v 1.9 1999/07/04 22:30:21 jsmith Exp $
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

package CGI::WeT;

use strict;
use Carp;
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);
use integer;
use CGI::WeT::Engine;
use CGI (qw(:all !header !start_html !end_html));

#
# The version of this package is the version Makefile.PL wants...
#

$VERSION = '0.70';

@ISA = (qw(CGI Exporter));

%EXPORT_TAGS = (%CGI::EXPORT_TAGS);
@EXPORT = (@CGI::EXPORT);
@EXPORT_OK = (@CGI::EXPORT_OK);

use CGI::WeT::Engine;
use CGI::WeT::User;
use CGI::WeT::Theme;
use CGI::WeT::Modules::Basic;

1;

=pod

=head1 NAME

CGI::WeT - Suite of modules to themeify a website

=head1 SYNOPSIS

    use CGI::WeT ();

Additional packages may be installed and used.  Please check with CPAN for the
latest collections.

=head1 DESCRIPTION

The collection of CGI::WeT::* modules allows a site to be built from three 
major components: (1) static themed html files, (2) theme definitions, (3) CGI
scripts.

This package (CGI::WeT) will load in the following packages only.  No symbols
are imported.

    CGI::WeT::Engine;
    CGI::WeT::User;
    CGI::WeT::Theme;
    CGI::WeT::Modules::Basic;

=head1 Themed HTML

Static files are built with no navigation or other theme-dependent information.
The file consists of a set of header lines followed by the body of the file
separated by a blank line.  For example

    Title: This is an example file

    <p>This file is an example of themed HTML</p>

This will produce a page with `This is an example file' as part of the title
in the head and the rest of the file as the body placed on the page according
to the theme in force.

=head1 Theme Definitions

This part of the package depends on which theme loader is being used.  A theme
definition provides the engine with the information it needs to produce a well
formed page.  See the appropriate CGI::WeT::Theme::Loader::*(3) page.

=head1 CGI Scripts

CGI scripts can be used to extend the functionality of the site and yet maintaina common look and feel according the themes.  See CGI::WeT::Engine(3) for
more details on interfacing with the rendering engine.

=head1 SEE ALSO

perl(1),
CGI::WeT::*(3),

CGI::WeT notes at C<http://www.jamesmith.com/cgi-wet/>

=head1 SUPPORT

Please send any questions or comments about CGI::WeT to me at
jsmith@jamesmith.com

=head1 AUTHORS

 Written by James G. Smith.
 Copyright (C) 1999.  Released under the Artistic License.

=cut

sub self_or_default {
    return @_ if defined($_[0]) && (!ref($_[0])) &&($_[0] eq __PACKAGE__);
    unless (defined($_[0]) && 
            (ref($_[0]) eq __PACKAGE__ || UNIVERSAL::isa($_[0],__PACKAGE__)) # slightly optimized for common case
            ) {
        my $thingy;
        if(ref(tied *STDOUT) ne __PACKAGE__) {
            my $stdout = tied *STDOUT;
            $thingy = tie *STDOUT, __PACKAGE__;
            $thingy->{'STDOUT'} = $stdout;
        } else {
            $thingy = tied *STDOUT;
        }
        unshift(@_,$thingy);
    }
    return @_;
}

sub rearrange {
    return CGI::rearrange(@_);
}

sub header {
    return '';
}

sub start_html {
    my($self,@p) = &self_or_default(@_);
    my($title,$author,$base,$xbase,$script,$noscript,$target,$meta,$head,$style,
$dtd,@other) = 
        $self->rearrange([qw(TITLE AUTHOR BASE XBASE SCRIPT NOSCRIPT TARGET META HEAD STYLE DTD)],@p);

    # strangely enough, the title needs to be escaped as HTML
    # while the author needs to be escaped as a URL
    
    $title = $self->escapeHTML($title || 'Untitled Document');
    $author = $self->escape($author);
    ($self->{'engine'})->headers_push('Title' => $title, 'Author' => $author);

    if ($meta && ref($meta) && (ref($meta) eq 'HASH')) {
        foreach (keys %$meta) { $self->{'engine'}->headers_push($_ => 
                                                                $meta->{$_}); }
    }

    $self->{'engine'}->{'doing_headers'} = 0;

    return '';
}

sub new {
    my $this = shift;
    my $thingy = { };

    my $class = ref($this) || $this;

    $thingy = CGI::new($class, '');
    $thingy->{'engine'} = CGI::WeT::Engine::_new 'CGI::WeT::Engine', @_;
    return $thingy;
}

sub TIEHANDLE { 
    my $self = new CGI::WeT @_;
    ($self->{'engine'})->{'doing_headers'} = 1;
    return $self;
}

sub DESTROY {
    #CGI::WeT::Engine::DESTROY(@_);
#    my $thingy = shift;
#    CGI::WeT::Engine::DESTROY($thingy->{'engine'});
}

sub PRINT {
    my $self = shift;
  
    ($self->{'engine'})->print(@_);
}

sub end_html {
    if(tied *STDOUT) {
        my $thingy = tied *STDOUT;
        if(ref $thingy eq __PACKAGE__) {
            untie *STDOUT;
            tie *STDOUT, ref($thingy->{'STDOUT'}), $thingy->{'STDOUT'} 
                if $thingy->{'STDOUT'};
        }
    }
    return '';
}
