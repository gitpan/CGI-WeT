#
# $Id: Calendar.pm,v 1.6 1999/05/30 16:49:32 jsmith Exp $
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

package CGI::WeT::Modules::Calendar;

use strict;
use Carp;
use vars qw($VERSION);

( $VERSION ) = '$Revision: 1.6 $ ' =~ /\$Revision:\s+([^\s]+)/;

=pod

=head1 NAME

CGI::WeT::Modules::Calendar - Extensions to engine to allow calendar
management

=head1 SYNOPSIS

    use CGI::WeT::Modules::Calendar ();

=head1 DESCRIPTION

This module provides rendering constructs to allow navigation through a set
of calendars.  Support is provided for multiple types of events in multiple
calendars, both public and private (general and user specific).

=head1 EXTENSIONS

=over 4

=item CGI::WeT::Modules::Calendar::initialize($engine, $r)

This subroutine will initialize the engine passed as $engine with information
from Apache (passed as $r).  The base URL for calendars is set with the
following.

    PerlSetVar WeT_CalendarURL /baseURL/

This is available for building URLs as @@CALENDAR@@.  For example, the top
level calendar can be viewed at the URL returned by

    $engine->url('@@CALENDAR@@/general/');

A list of available calendars might be found at

    $engine->url('@@CALENDAR@@/');

=cut

sub initialize {
    my $engine = shift;
    my $r = shift;

    my($dayformat, $eventformat) = (
				    $engine->content_pop,
				    $engine->content_pop
				    );

    if($engine->{'MOD_PERL'}) {
	$engine->{'URLBASES'}->{'CALENDAR'} = 
	    $r->dir_config('WeT_CalendarURL');
    }
    return 1;
}

sub CGI::WeT::Modules::CALENDAR_SUMMARY {
    my $engine = shift;

    my($dayformat, $eventformat) = ($engine->content_pop,
				    $engine->content_pop);

    my @output;

    my(@months_abbr) = ('Jan', 'Feb', 'Mar', 'Apr',
                        'May', 'Jun', 'Jul', 'Aug',
                        'Sep', 'Oct', 'Nov', 'Dec');

    my(@months) = ('January',   'February', 'March',    'April',
		   'May',       'June',     'July',     'August',
		   'September', 'October',  'November', 'December');

    my(@months_len) = (31, 28, 31, 30,
		       31, 30, 31, 31,
		       30, 31, 30, 31);

    my(@dows) = ('Sunday',   'Monday', 'Tuesday',  'Wednesday',
		 'Thursday', 'Friday', 'Saturday', 'Sunday'   );

    my ($sec,$min,$hour,$mday,$mon,$yr,$wday,$yday,$isdst) =
    localtime(time);

    my($month) = $engine->argument('month') || ($mon+1);
    
    my($year) = $engine->argument('year') || ($yr+1900);

    my($calendar) = $engine->argument('calendar');

    if($calendar eq 'personal' && $engine->argument('user')) {
	$calendar .= '/' . $engine->argument('user');
    } else {
	$calendar = 'general';
    }

    my $dir = join('/',
		   $engine->filename($engine->url('@@CALENDAR@@')),
		   $calendar,
		   $year,
		   $month,
		   );

    return '' unless -e $dir;

    my(@files);

    $months_len[1]++
	if($month == 2 && 
	   ($year % 4 == 0) && 
	   ($year % 100 != 0 || $year % 400 == 0)
	   );
    my($i, $lasti) = (1, $months_len[$month-1]+1);
    while($i < $lasti) {
	if(opendir OD, "$dir/$i") {
	    @files = grep(/^\d/ && /\.thtml$/, readdir(OD));
	    closedir OD;
	    if(@files) {
		my @contents;

		$engine->content_push([ $dows[&get_dow($year, $month, $i)],
					", ", $months[$month-1],
					" $i" ],
				      $dayformat);
		push(@output, $engine->render_content);
		foreach my $file (@files) {
		    my(@body, $text, $key, $val);
		    my $headers = {};
		    open IN, "<$dir/$i/$file";

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

		    $$headers{'Description'} = $text;

		    push(@contents, $headers);
		}
		@contents = (sort { $$a{Starttime} cmp $$b{Starttime} }
			          @contents);

		foreach my $event (@contents) {
		    $engine->content_push([ [ $event->{'Description'} ], 
					    '[TEXT]' ],
					  $eventformat);
		    push(@output, $engine->render_content);
		}
	    }
	}
    } continue {
	$i++;
    }
    return @output;
}

sub get_dow {
    my($year, $mon, $day) = @_;

    return (localtime(timelocal(0,0,0, $day, $mon-1, $year-1900)))[6];
}

1;
