#
# $Id: Documentation.pm,v 1.3 1999/06/10 00:48:59 jsmith Exp $
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

package CGI::WeT::Modules::Documentation;

use strict;
use Carp;
use vars qw($VERSION);

( $VERSION ) = '$Revision: 1.3 $ ' =~ /\$Revision:\s+([^\s]+)/;

=pod 

=head1 NAME

CGI::WeT::Modules::Documentation - Extensions to engine to allow documentation
management

=head1 SYNOPSIS

    use CGI::WeT::Modules::Documentation ();


=head1 DESCRIPTION

This module provides rendering constructs to allow navigation through a set
of pages.  Support is provided for a doubly linked list of pages.

=head1 EXTENSIONS

=over 4

=item CGI::WeT::Modules::Documentation::initialize($engine, $r)

This subroutine will initialize the engine passed as $engine with information
from Apache (passed as $r).  There is no significant code.

=cut

sub initialize {
    #my $engine = shift;
    #my $r = shift;

    return 1; 
}

=pod

=item DOC_NEXT

This extension is like CGI::WeT::Modules::Basic's B<LINK> in that the top of
the content stack is made into a link.  The location is determined by the
values of the arguments.

=over 4

=item sequence

This can be either `next' or `prev.'

=back 4

=cut

# ' for Emacs
# ` for Emacs

sub CGI::WeT::Modules::DOC_NEXT {
    my $engine = shift;

    my $sequence = $engine->argument('sequence');
    my $file = $engine->header(ucfirst $sequence);

    return '' unless $file;

    my $nowfile = $engine->uri();

    $nowfile =~ s{/[^/]+$}{/};
    $file = $nowfile . $file if($file !~ m{^/});

    return ("<a href=\"$file\">", $engine->render_content, "</a>");
}

1;
