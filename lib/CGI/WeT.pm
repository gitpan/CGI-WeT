#
# $Id: WeT.pm,v 1.4 1999/05/14 01:13:06 jsmith Exp $
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

package CGI::WeT;

use strict;
use Carp;
use vars qw($VERSION);
use integer;

#
# The version of this package is the version Makefile.PL wants...
#

$VERSION = '0.6.4';

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

CGI::WeT notes at C<http://people.physics.tamu.edu/jsmith/wet-perls/>

=head1 SUPPORT

Please send any questions or comments about CGI::WeT to me at
jsmith@nostrum.com

=head1 AUTHORS

 Written by James G. Smith.
 Copyright (C) 1999.  Released under the Artistic License.

=cut
