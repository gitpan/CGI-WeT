#
# $Id: WeT.pm,v 1.10 1999/11/19 05:41:18 jsmith Exp $
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
use integer;
use vars qw($VERSION @ISA $AutoloadClass);
require CGI;

use Carp;
use CGI::WeT::Engine;
use CGI::WeT::Theme;
use CGI::WeT::Modules::Basic;

#
# The version of this package is the version Makefile.PL wants...
#

$VERSION = '0.71';

@ISA = (qw(CGI));

$CGI::DefaultClass = 'CGI::WeT';
$AutoloadClass = 'CGI';

sub new {
  my $self = CGI::new(@_);

  $self->{'CGI::WeT'}->{STDOUT} = tied *STDOUT;
  tie *STDOUT, ref $self, $self;

  return $self;
}

sub TIEHANDLE {
  my $class = shift;
  my $self = shift;

  unless(ref $self) {
    $self = $class->new(@_);
  }

  $self->{'CGI::WeT'}->{Engine} = new CGI::WeT::Engine; 
  $self->{'CGI::WeT'}->{Engine}->set_query_object($self);
  return $self;
}
  

sub PRINT {
  my $self = shift;

  ${$$self{'CGI::WeT'}}{Engine}->print(@_);
}

sub DESTROY {
  my $self = shift;

  #untie *STDOUT;
  delete ${$$self{'CGI::WeT'}}{Engine};
}

sub header {
  my($self,@p) = CGI::self_or_default(@_);
  my $type;

  if(@p == 1) {
    $type = $p[0];
  } else {
    my %p = @p;
    $type = $p{'-type'} || $p{type};
  }

  if($type eq 'text/html' or not $type) {
    tie *STDOUT, 'CGI::WeT', $self unless(ref(tied *STDOUT) eq 'CGI::WeT');
  } else {
    untie *STDOUT if(ref(tied *STDOUT) eq 'CGI::WeT');
    if(${$$self{'CGI::WeT'}}{Engine}) {
      ${$$self{'CGI::WeT'}}{Engine}->internal_use_only;
      ${$$self{'CGI::WeT'}}{Engine}->DESTROY;
      delete ${$$self{'CGI::WeT'}}{Engine};
      ${$$self{'CGI::WeT'}}{Engine} = tied *STDOUT;
    }
  }

  $self->{'CGI::WeT'}->{'Engine'}->{'doing_headers'} = 0;

  return CGI::header($self,@p);
}

sub start_html {
    my($self,@p) = CGI::self_or_default(@_);
    my($title,$author,$base,$xbase,$script,$noscript,$target,$meta,$head,$style,
$dtd,@other) = 
        $self->rearrange([qw(TITLE AUTHOR BASE XBASE SCRIPT NOSCRIPT TARGET META HEAD STYLE DTD)],@p);

    # strangely enough, the title needs to be escaped as HTML
    # while the author needs to be escaped as a URL
    
    $title = $self->escapeHTML($title || 'Untitled Document');
    $author = $self->escape($author);
    ${$$self{'CGI::WeT'}}{Engine}->headers_push('Title' => $title, 'Author' => $author);

    if ($meta && ref($meta) && (ref($meta) eq 'HASH')) {
        foreach (keys %$meta) { $self->{'CGI::WeT'}->{Engine}->headers_push($_ => 
                                                                $meta->{$_}); }
    }

    $self->{'CGI::WeT'}->{'Engine'}->{'doing_headers'} = 0;

    return '';
}

sub end_html {
  return '';
}

sub show_page {
  my $class = shift;
  $class = ref($class) || $class;
  if(ref tied *STDOUT eq $class) {
    (tied *STDOUT)->DESTROY;
  }
}

1;
__END__

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

    CGI
    CGI::WeT::Engine
    CGI::WeT::Theme
    CGI::WeT::Modules::Basic

=head1 Themed HTML

Static files are built with no navigation or other theme-dependent information.
The file consists of a set of header lines followed by the body of the file
separated by a blank line.  For example

    Title: This is an example file

    <p>This file is an example of themed HTML</p>

This will produce a page with `This is an example file' as part of the title
in the head and the rest of the file as the body placed on the page according
to the theme in force.

CGI::WeT::Engine provides the mod_perl handler for static pages.

=head1 Theme Definitions

This part of the package depends on which theme loader is being used.  A theme
definition provides the engine with the information it needs to produce a well
formed page.  See the appropriate CGI::WeT::Theme::Loader::*(3) page.

=head1 CGI Scripts

CGI::WeT can be used in place of CGI with minor modifications.  Replace
the B<use CGI> statement with B<use CGI::WeT> at the top of the script
and add a line to the close of the script: B<CGI::WeT->show_page>.

The following is an example based on the CGI.pm book:

  #!/usr/bin/perl
  # Script: plaintext2.pl
  use CGI::WeT ':standard';

  print header('text/html');
  print start_html(-title => 'PlainText2.CGI');
  print "Jabberwock\n\n";
  print "'Twas brillig, and the slithy toves\n";
  print "Did gyre and gimbol in the wave.\n";
  print "All mimsy were the borogroves,\n";
  print "And the mome raths outgrabe....\n";
  print end_html();

  CGI::WeT->show_page;

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

