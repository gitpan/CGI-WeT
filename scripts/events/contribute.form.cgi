#! /usr/bin/perl

# $Id: contribute.form.cgi,v 1.12 1999/05/30 16:52:35 jsmith Exp $
#
# Author: James G. Smith
#
# Copyright (C) 1998, 1999
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

#
# This script is based on the previous one used on the dept. website.
# The style will be a little different than the usual themeing code
# as a result.
#

use strict;
use CGI qw/:standard :html3/;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
    localtime(time);

restore_parameters("");  # we don't want CGI trying to read anything on POST.

{
    my $engine = new CGI::WeT::Engine;
    my($person, $action, $userstuff, $e, $r);

    $engine->headers_push('Title' => 
			  $engine->{'SITENAME'} . " Calendar Submissions");
    
    if($ENV{REMOTE_USER}) {
	my(%selected);
	$selected{$engine->argument('calendar') || 'general'} = " selected";
	$action = $engine->url('/@@CALENDAR@@/contribute.form.private.cgi');
	$userstuff = <<1HERE1
You are logged in as <strong>$ENV{REMOTE_USER}</strong>.
<br>
Calendar:
<select name=\"calendar\">
<option value=\"general\"$selected{'general'}>General</option>
<option value=\"personal\"$selected{'personal'}>Personal</option>
</select>
1HERE1
    ;
	$person = new CGI::WeT::User;
    } else {
	$person = default CGI::WeT::User;
	$action = $engine->url('/@@CALENDAR@@/contribute.form.cgi');
	my($name, $email) =
	    ($engine->argument('name'), $engine->argument('email'));
	$userstuff = <<1HERE1
Your Name<br>
<input name="name" value="$name" type="text" size=50>
<p>
Your Email or Homepage<br>
<input type="text" name="email" value="$email" size=50><br>
<small>(Leave these blank if you want to be anonymous)</small>
1HERE1
    ;
    }

    my($point) = 'initial';
    my($default, $desired, $required, $category);

    if($ENV{'REQUEST_METHOD'} eq 'POST' &&
       $engine->argument('Start_Over') ne 'Start Over') {
	if(($engine->argument('Submit_Type')     ||
	    $engine->argument('Submit_Overview') ||
	    $engine->argument('Submit_Commit'))  &&
	   defined $$CGI::WeT::Calendar::category{$engine->argument('type')}) {
	    
	    $e = $engine->argument('type');
	    $point = 'data entry' if $person->allowed($e);
	    
	    $category = $CGI::WeT::Calendar::category->{$e};
	    $default = $CGI::WeT::Calendar::category->{'default'};
	    
	    $desired = $category->{'desired'} . ' ' .
		$default->{'desired'};
	    $required = $category->{'required'} . ' ' .
		$default->{'required'};
	    
	    foreach (split(/\s+/, $category->{'not-desired'})) {
		$desired =~ s/\b$_\b//g;
	    }
	    
	    foreach (split(/\s+/, $category->{'not-required'})) {
		$required =~ s/\b$_\b//g;
	    }
	    
	    $r = 1;
	    
	    foreach $e (split(/\s+/, $required)) {
		next if $e =~ /^\s*$/;
		$r &&= &filledEntry($e, $engine);
	    }
	    
	    $point = 'overview' if $r && $engine->argument('Submit_Overview');
	    $point = 'commit' if $r && $engine->argument('Submit_Commit');
	}
    }

    $engine->print(p, "We are at the point of '$point'.", p);
    my $startform = startform('POST', $action, $CGI::URL_ENCODED);

    if($point eq 'initial') {
	$engine->print(p,
		       $startform,
		       $userstuff,
		       p,
		       'Creating an event for the calendar is a three to four ',
		       'step process to help prevent accdental errors.',
		       p,
		       'The first step is to choose the event type:',
		       popup_menu(-name => 'type',
				  -values => [
					      grep($_ ne 'default' &&
						   $person->allowed($_),
						   keys 
						   %$CGI::WeT::Calendar::category
						   )
					      ],
				  -labels => {
				      map(($_, 
					   $CGI::WeT::Calendar::category
					   ->{$_}->{'name'}),
					  keys %$CGI::WeT::Calendar::category)
				      },
				  -default => ($engine->argument('type') || '')
				  ),
		       p,
		       '<center>',
		       submit(-name => 'Submit_Type',
			      -value=> 'Submit'
			      ),
		       '</center>',
		       endform
		       );
    } elsif($point eq 'data entry') {
	$engine->print(p,
		       $startform,
		       $userstuff,
		       p,
		       'Creating an event for the calendar is a three to four ',
		       'step process to help prevent accidental errors ',
		       '(assuming some errors are not accidental). ',
		       p,
		       'The second step is to fill out as much information as ',
		       'possible.  Certain items are marked as required.  If ',
		       'these are not entered, you will be stuck on this second ',
		       'step...',
		       p,
		       'You have chosen an event of type ',
		       strong(
			      $CGI::WeT::Calendar::category ->
			      {$engine->argument('type')} -> {'name'}
			      ),
		       '.  The category of an event cannot be changed after the ',
		       'event is committed.  If this category is inappropriate ',
		       'or wrong, you will need to start over (button at bottom ',
		       'of page).',
		       p,
		       hidden(-name => 'type',
			      -value => $engine->argument('type')
			      ),
		       );
	if($desired =~ /^\s*$/ && $required =~ /^\s*$/) {
	    $engine->print('It appears that this event type (',
			   $CGI::WeT::Calendar::category ->
			   {$engine->argument('type')} -> {'name'},
			   ") doesn't allow any information to be input.  This ",
			   'may be a configuration error.  Please contact the ',
			   'webmasters at ',
			   '<a href="mailto:@@EMAIL@@">@@EMAIL@@</a>.'
			   );
	} else {
	    my($needed) = "$desired $required";
	    #
	    # At this point, we want to put certain ones at the top
	    # others will follow in arbitrary order...
	    #
	    foreach $e (grep($needed =~ /\b$_\b/, (
			     qw/title date starttime endtime description speaker/,
			     qw/url contact sponsor audience/
						   )
			     )
			) {
		$needed =~ s/\b$e\b//g;
		$engine->print(&formatEntry($e, $required =~ /\b$e\b/ || 0, 
					    $engine));
	    }
	    foreach $e (split(/\s+/, $needed)) {
		if($needed =~ /\b$e\b/) {
		    $needed =~ s/\b$e\b//g;
		    $engine->print(&formatEntry($e, $required =~ /\b$e\b/ || 0,
						$engine));
		}
	    }
	    $engine->print('<center>',
				  submit(-name => 'Submit_Overview',
					 -value => 'Submit'
					 ),
				  submit(-name => 'Start_Over',
					 -value => 'Start Over'
					 ),
				  reset(-value => 'Reset'),
			    '</center>'
			   );     
	}
	$engine->print(
		       endform
		       );
    } elsif($point eq 'overview') {
	$engine->print(p,
		       $startform,
		       $userstuff,
		       p,
		       'Creating an event for the calendar is a three to four ',
		       'step process to help prevent accidental errors ',
		       '(assuming some errors are not accidental). ',
		       p,
		       'The third step is to double-check the information. ',
		       'If there are any errors, go back in the browser to ',
		       'the previous page and make corrections.',
		       p,
		       'You have chosen an event of type ',
		       strong(
			      $CGI::WeT::Calendar::category ->
			      {$engine->argument('type')} -> {'name'}
			      ),
		       '.  The category of an event cannot be changed after the ',
		       'event is committed.  If this category is inappropriate ',
		       'or wrong, you will need to start over (button at bottom ',
		       'of page).<br><br>',
		       hidden(-name => 'type',
			      -value => $engine->argument('type')
			      ),
		       );
	if($desired =~ /^\s*$/ && $required =~ /^\s*$/) {
	    $engine->print('It appears that this event type (',
			   $CGI::WeT::Calendar::category ->
			   {$engine->argument('type')} -> {'name'},
			   ") doesn't allow any information to be input.  This ",
			   'may be a configuration error.  Please contact the ',
			   'webmasters at ',
			   '<a href="mailto:@@EMAIL@@">@@EMAIL@@</a>.'
			   );	
	} else {
	    my($needed) = "$desired $required";
	    #
	    # At this point, we want to put certain ones at the top
	    # others will follow in arbitrary order...
	    #
	    foreach $e (grep($needed =~ /\b$_\b/, (
	       	     qw/title date starttime endtime description speaker/,
	      	     qw/url contact sponsor audience/
						   )
			     )
			) {
		$needed =~ s/\b$e\b//g;
		$engine->print(&printEntry($e, $required =~ /\b$e\b/ || 0, 
					    $engine));
	    }
	    foreach $e (split(/\s+/, $needed)) {
		if($needed =~ /\b$e\b/) {
		    $needed =~ s/\b$e\b//g;
		    $engine->print(&printEntry($e, $required =~ /\b$e\b/ || 0,
						$engine));
		}
	    }
	    $engine->print('<center>',
			   submit(-name => 'Submit_Commit',
				  -value => 'Submit'
				  ),
			   submit(-name => 'Start_Over',
				  -value => 'Start Over'
				  ),
			   reset(-value => 'Reset'),
			   '</center>'
			   );     
	}
	$engine->print(
		       endform
		       );
    } elsif($point eq 'commit') {
	my($text, $dir);
	my($needed) = "$desired $required";
	#
	# The filename is based on the year/month/day of the event
	#
	my($fyear, $fmon, $fday) =
	    (
	     $engine->argument('date_year'),
	     $engine->argument('date_month'),
	     $engine->argument('date_day')
	     );
	my($calendar) = $engine->argument('calendar') || 'general';
	if($calendar eq 'personal') {
	    $calendar .= '/' . $person->{'username'};
	} else {
	    $calendar = 'general';
	}
	if($ENV{REMOTE_USER} && ($ENV{REMOTE_USER} !~ /unknown/i)) {
	    $dir = $engine->filename($engine->url('/@@CALENDAR@@/')) . '/' .
		join('/', $calendar, $fyear, $fmon, $fday ) . '/';
	} else {
	    $dir = $engine->filename($engine->url('/@@CALENDAR@@/')) . '/' .
		join('/', 'todo', $calendar) . '/';
	}
	my $type = $engine->argument('type');
	$type =~ /([-A-Za-z0-9_]+)/;
	my $filename = join('.', time(), $$, $1, 'thtml');
	$dir = &makeDirectories($dir); # $dir should be untainted upon return

	my $fh = new IO::File;
	if($fh->open(">$dir$filename")) {

	    #
	    # first put in the author/link headers
	    #

	    my($author, $link, $authenticatedas) = ( '', '', '' );
	
	    $author = $engine->argument('name');
	    $author ||= $engine->{'AC'}
	        if($engine->argument('email') =~ /^\s*$/);
	    if($engine->argument('email') =~ /\@/) {
		$link = "<a href=\"mailto:" . 
		    $engine->argument('email') . "\">$author\...?</a>";
	    } elsif($engine->argument('email')) {
		$link = "<a href=\"" . $engine->argument('email') .
		    "\">$author\...?</a>";
	    } else {
		$link = "$author\...?";
	    }

	    if($ENV{REMOTE_USER} && ($ENV{REMOTE_USER} !~ /unknown/i)) {    
		$person = new CGI::WeT::User;
		$author = $person->{'familiarName'} || 
		    $ENV{REMOTE_USER};
		$authenticatedas = $ENV{REMOTE_USER};
		if($$person{'mail'} !~ /^\s*$/) {
		    $link = "<a href=\"mailto:$$person{'mail'}\">$$person{'familiarName'}</a>";
		} elsif($$person{www_url} !~ /^\s*$/) {
		    $link = "<a href=\"$$person{www_url}\">$$person{familiarName}</a>";
		} else {
		    $link = $$person{familiarName} || $ENV{REMOTE_USER};
		}
	    }

	    $fh->print("Author: $author\n",
		       "Link: $link\n");
	    $fh->print("AuthenticatedAs: $authenticatedas\n")
		if $authenticatedas;

	    #
            # page types in decreasing order of importance
            #

	    my $type = $engine->argument('type');
	    $fh->print("Type: CALENDAR_", "\U$type", " CALENDAR_EVENT ",
		       "CALENDAR\n");

	    #
	    # put out all the event specific information
	    #

	    foreach $e (grep($_ ne 'description' 
			     && &filledEntry($_, $engine),
			     split(/\s+/, $needed))) 
	    {
		next unless $needed =~ /\b$e\b/;
		$needed =~ s/\b$e\b//g;
		my($field_info) = $$CGI::WeT::Calendar::fields{$e};
		if($field_info->{'type'} eq 'text' ||
		   $field_info->{'type'} eq 'area')
		{
		    $text = $engine->argument($e);
		    $text =~ s/\r\n+/ /g;
		    $fh->print("\u$e: $text\n");
		}
		elsif($field_info->{'type'} eq 'select' ||
		      $field_info->{'type'} eq 'checkbox')
		{
		    $text = $engine->argument($e);
		    $text =~ s/\r\n+/ /g;
		    $fh->print("\u$e: $text\n");
		}
		elsif($field_info->{'type'} eq 'date')
		{
		    $fh->print("\u$e: ", 
			       join(' ', $engine->argument("$e\_day"),
				    $engine->argument("$e\_month"),
				    $engine->argument("$e\_year")),
			       "\n");
		}
		elsif($field_info->{'type'} eq 'time')
		{
		    $fh->print("\u$e: ", 
			       $engine->argument("$e\_hour"), ':',
			       $engine->argument("$e\_minute"), ' ',
			       $engine->argument("$e\_ampm"), "\n"
			       );
		}
	    }
	    if($needed =~ /\bdescription\b/) {
		$fh->print("\n",
			   $engine->smarttext(
					      $engine->argument('description')
					      )
			   );
	    }
	    $fh->close;
	} else {
	    $engine->print(<<1HERE1);
<p>The following error occured during the processing of the calendar entry.
(in $dir/$filename for $fday $fmon $fyear)
</p><p>
$!
</p>
1HERE1
	}
    }
}

# Support subroutines...

sub formatEntry {
    my($field, $required, $engine) = @_;
    my(@output);
    my($i, $e);
    my(@months_abbr) = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
    my(@months) = ('January',   'February', 'March',    'April',
                   'May',       'June',     'July',     'August',
                   'September', 'October',  'November', 'December');
    my(@minutes) = ('00', '05', '10', '15', '20', '25', '30', '35',
                    '40', '45', '50', '55');
    my($field_info) = $CGI::WeT::Calendar::fields->{$field};
    return '' if(!defined $field_info);
    @output = ("$$field_info{name}: ");
    push(@output, "(required) ") if $required;
    push(@output, "<br>");
    if($$field_info{'type'} eq 'text') {
        $e = $engine->argument("$field");
        $e =~ s/\"/&quot;/;
	push(@output, textfield(
				-name => $field,
				-value => $e,
				-size => ($field_info->{'size'} || 40)
				)
	     );
    } elsif($$field_info{'type'} eq 'area') {
	push(@output, textarea(
			       -name => $field,
			       -wrap => 1,
			       -rows => ($field_info->{'rows'} || 10),
			       -cols => ($field_info->{'cols'} || 60),
			       -value => $engine->argument("$field")
			       )
	     );
    } elsif($$field_info{'type'} eq 'select') {
        push(@output, "<select name=\"$field\"");
        push(@output, " multiple") if $$field_info{multiple};
        push(@output, ">");
        foreach $e (keys(% { $$field_info{selections} })) {
            push(@output, "<option value=\"$e\"");
            push(@output, " selected") 
		if $engine->argument($field) =~ /\b$e\b/;
            push(@output, ">$$ { $$field_info{selections}}{$e}</option>");
        }
        push(@output, "</select>");
    } elsif($$field_info{'type'} eq 'checkbox') {
        foreach $e (keys(% { $$field_info{selections} })) {
            push(@output, "<input name=\"$field\" value=\"$e\"");
            push(@output, " checked") if $engine->argument($field) =~ /\b$e\b/;
            push(@output, ">$$ { $$field_info{selections}}{$e}</option>");
        }
    } elsif($$field_info{'type'} eq 'date') {
        push(@output, "<select name=\"$field\_month\"><option value=\"\">Month</option>");
        for $i (0..11) {
            push(@output, "<option value=\"$months_abbr[$i]\"");
            push(@output, " selected") 
		if $months_abbr[$i] eq $engine->argument("$field\_month");
            push(@output, ">$months[$i]</option>");
        }
        push(@output, "</select><select name=\"$field\_day\"><option value=\"\">Day</option>");
        for $i (1..31) {
            push(@output, "<option values=\"$i\"");
            push(@output, " selected")
		if $i == $engine->argument("$field\_day");
            push(@output, ">$i</option>");
        }
        push(@output, "</select><select name=\"$field\_year\"><option value=\"\">Year</option>");

        my($minyear) = $year;
        if($minyear < 50) {
            $minyear += 2000;
        } else {
            $minyear += 1900;
        }
        my($maxyear) = $minyear+6;

        for $i ($minyear .. $maxyear) {
            push(@output, "<option value=\"$i\"");
            push(@output, " selected")  
		if $i == $engine->argument("$field\_year");
            push(@output, ">$i</option>");
        }
        push(@output, "</select>");
    } elsif($$field_info{'type'} eq 'time') {
        push(@output, "<select name=\"$field\_hour\"><option value=\"\">Hour</option>");
        for $i (1..12) {
            push(@output, "<option value=\"$i\"");
            push(@output, " selected") 
		if $engine->argument("$field\_hour") == $i;
            push(@output, ">$i</option>");
        }
        push(@output, "</select><select name=\"$field\_minute\"><option value=\"\">Minute</option>");
        for $i (0..$#minutes) {
            push(@output, "<option value=\"$minutes[$i]\"");
            push(@output, " selected") 
		if $engine->argument("$field\_minute") == $minutes[$i];
            push(@output, ">$minutes[$i]</option>");
        }
        push(@output, "</select><select name=\"$field\_ampm\"><option value=\"\">am/pm</option>");
        foreach $i ('am', 'pm') {
            push(@output, "<option value=\"$i\"");
            push(@output, " selected") 
		if $i eq $engine->argument("$field\_ampm");
            push(@output, ">$i</option>");
        }
        push(@output, "</select>");
    }
    push(@output, "<br>");

    return @output;
}

sub printEntry {
    my($field, $required, $engine) = @_;
    my(@output);
    my($i, $e);
    my(@months_abbr) = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
    my(@minutes) = ('00', '05', '10', '15', '20', '25', '30', '35',
                    '40', '45', '50', '55');
    my($divperhour);

    {
        use integer;
        $divperhour = 60 / scalar(@minutes);
    }

    my($field_info) = $CGI::WeT::Calendar::fields->{$field};
    return '' if(!defined $field_info);
    @output = ("$$field_info{name}: ");
    if($$field_info{'type'} eq 'text') {
        $e = $engine->argument($field);
        $e =~ s/\"/&quot;/g;
        push(@output, "<strong>$e</strong>");
        push(@output, "<input type=\"hidden\" name=\"$field\" value=\"$e\">");
    } elsif($$field_info{'type'} eq 'area') {
        push(@output, "<br><center><table border=1 cellpadding=2 ",
	     "cellspacing=2 width=\"90%\"><tr><td>", 
	     $engine->argument($field), "</td></tr></table></center>");
        $e = $engine->argument($field);
        $e =~ s/\"/&quot;/;
        push(@output, "<input type=\"hidden\" name=\"$field\" value=\"$e\">");
    } elsif($$field_info{'type'} eq 'select' ||
            $$field_info{'type'} eq 'checkbox') {
        # we can have multiple choices separated by whitespace
        $e = $engine->argument($field);
        $e =~ s/\"/&quot;/;
        push(@output, "<input type=\"hidden\" name=\"$field\" value=\"$e\">");
        push(@output, "<strong>",
             join("</strong>, <strong>",
                  map($ { $$field_info{'selections'}}{$_},
                      grep(exists($ { $$field_info{'selections'}}{$_}),
                           split(/\s+/, $engine->argument($field))
                           )
                      )
                  ),
             "</strong>");
    } elsif($$field_info{'type'} eq 'date') {
        push(@output, "<strong>",
             join(" ", $engine->argument("$field\_day"), 
		  $engine->argument("$field\_month"),
                  $engine->argument("$field\_year")),
             "</strong>");
        foreach ("$field\_day", "$field\_month", "$field\_year") {
            my($e) = $engine->argument($_);
            $e =~ s/\"/&quot;/;
            push(@output, "<input type=\"hidden\" name=\"$_\" value=\"$e\">");
        }
    } elsif($$field_info{'type'} eq 'time') {
        push(@output, "<strong>",
             join(":", $engine->argument("$field\_hour"),
                  $engine->argument("$field\_minute")),
             " ", $engine->argument("$field\_ampm"), "</strong>");
        foreach ("$field\_hour", "$field\_minute", "$field\_ampm") {
            my($e) = $engine->argument($_);
            $e =~ s/\"/&quot;/;
            push(@output, "<input type=\"hidden\" name=\"$_\" value=\"$e\">");
        }
    }
    push(@output, "<br>");

    return @output;
}

sub filledEntry {
    my($field) = shift;
    my($engine) = shift;
    my(%months_abbr) = ('Jan', 31, 'Feb', 28, 'Mar', 31, 'Apr', 30,
                        'May', 31, 'Jun', 30, 'Jul', 31, 'Aug', 31,
                        'Sep', 30, 'Oct', 31, 'Nov', 30, 'Dec', 31);
    my($r);

    my($field_info) = $$CGI::WeT::Calendar::fields{$field};
    if(defined $field_info) {
        if($$field_info{'type'} eq 'date') {
            $months_abbr{'Feb'}++ 
		if($engine->argument("$field\_year") % 4 == 0);
            return exists($months_abbr{$engine->argument("$field\_month")}) &&
                $engine->argument("$field\_day") <= 
		    $months_abbr{$engine->argument("$field\_month")}
            && $engine->argument("$field\_year") > 1998;
        } elsif($$field_info{'type'} eq 'time') {
            return( $engine->argument("$field\_hour") > 0 
		    && $engine->argument("$field\_hour") < 13
                    && $engine->argument("$field\_minute") >= 0
                    && $engine->argument("$field\_minute") < 60
                    && $engine->argument("$field\_ampm") =~ /^[ap]m$/);
        } else {
            return $engine->argument("$field") !~ /^\s*$/;
        }
    } else {
        return undef;
    }
}

sub makeDirectories {
    my($dir) = @_;
    my(@dirs, $mydir);
    $dir =~ s{/../}{/}g;
    $dir =~ /([^;]+)/;
    $dir = $1;
    $dir =~ s{//}{/}g;

    unless(-e $dir) {
        @dirs = split('/', $dir);
        $mydir = '/';
        while(@dirs) {
	    $mydir .= '/' . shift @dirs;
            unless(-e $mydir) {
                mkdir($mydir, 0755) || die "Could not create $mydir";
                chmod(0755, $mydir);
            }
        }
    }
    (-d $dir) || die "It seems that $dir exists, but is not a directory.  This needs to be made a directory.\n";
    return $dir;
}
