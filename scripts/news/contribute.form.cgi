#! /usr/bin/perl

#
# $Id: contribute.form.cgi,v 1.6 1999/05/30 16:52:35 jsmith Exp $
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

use strict;
use CGI qw/:standard :html3/;

{
    my $engine = new CGI::WeT::Engine;
    my($action, $userstuff);

    $engine->headers_push('Title' => $engine->{'SITENAME'} . " Submissions");

    if($ENV{REQUEST_METHOD} eq 'GET') {
	if($ENV{REMOTE_USER}) {
	    $action = $engine->url('@@NEWS@@/', 'contribute.form.private.cgi');
	} else {
	    $action = $engine->url('@@NEWS@@/', 'contribute.form.cgi');
	}
	
	if($ENV{REMOTE_USER}) {
	    $userstuff = <<1HERE1
You are logged in as <strong>$ENV{REMOTE_USER}</strong>.
1HERE1
    ;
	} else {
	    $userstuff = <<1HERE1
Your Name<br>
<input name="name" value="$ENV{REMOTE_USER}" type="text" size=50>
<p>
Your Email or Homepage<br>
<input type="text" name="email" value="" size=50><br>
<small>(Leave these blank if you want to be anonymous, URLs must be prefixed
with <tt>http://</tt>)</small>
1HERE1
    ;
	}

	$engine->print(<<1HERE1);
<p>
Do you have something you'd like to share with everyone else?  Fill out this
form and it'll get stashed somewhere safe until it's been poked, prodded, and
most likely posted.
</p><p>
If you have an editorial, an idea for an editorial, a question about this site,
or anything besides a simple story, we would prefer you email it
<a href="mailto:$engine->{'EMAIL'}">to us</a>.  The opposite is true - please use this
form if you have a story.  This form organizes things intelligently and makes
our life much easier.  Please use it!
</p>
1HERE1
# ' for Emacs
# ` for Emacs
    ;
	if($engine->{'EMAIL'} ne $engine->{'PROBLEMS_EMAIL'}) {
	    $engine->print(<<1HERE1);
<p>
<strong>Please</strong> also note that this is the wrong place to mail bug
reports or complaints.  Those should be submitted as
<a href="mailto:$engine->{'PROBLEMS_EMAIL'}">problems</a>.
</p>
1HERE1
    ;
	}

	$engine->print(
		       p,
		       startform('POST', $action, $CGI::URL_ENCODED),
		       $userstuff,
		       p,
		       'Subject (descriptive! clear! simple!)<br>',
		       textfield(-name => 'subject',
				 -default => '',
				 -size => 50),
		       '<br><small>',
		       "(bad subjects='Check This Out!' or 'An Article'. ",
		       "If yours isn't clear, it'll be deleted!)</small>",
		       p,
		       "Please select the closest category<br>",
		       );
	my(%types);
	if(open IN, "<" . $engine->filename($engine->url('@@NEWS@@/',
				     $engine->argument('channel') || 'general',
							 '/topics.txt'))) {
	    my($k, $v);
	    while(<IN>) {
		($k, $v) = split(/:/, $_, 2);
		$types{$v} = $k;
	    }
	}
	$types{'news'} = 'News';
	$types{''} = 'All Topics';

	$engine->print(popup_menu(-name => 'category',
				  -values => [keys %types],
				  -labels => \%types,
				  -default => 'news'),
		       p,
		       "The Scoop (Put a blank line between paragraphs. ",
		       "Text can be made ",
		       strong('*bold*'), ' and ',
		       em('_italic_'),
		       ".  Please format URLs as",
		       "<tt>&lt;URL:...&gt;</tt> (for example,", 
		       "<tt>&lt;URL:http://www.tamu.edu/&gt;</tt> for a link ",
		       "to the homepage for Texas A&amp;M University.) )<br>",
		       textarea(-name => 'story',
				-default => '',
				-rows => 15,
				-wrap => 'hard',
				-columns => 50),
		       '<br>',
		       "<small>(Are you sure you included a URL?)</small>",
		       p,
		       submit(-name => 'submit',
			      -value => 'Submit Story'),
		       endform);
    } elsif($ENV{REQUEST_METHOD} eq 'POST') {
	my($filedir, $person);
	my $servername = $ENV{'SERVER_NAME'};
	my $filename = time() . ".$$." . 
	    $engine->argument('category') . ".thtml";
	my $fileurl = $engine->url('@@NEWS@@/',
			       $engine->argument('channel') || 'general', '/',
				   $filename);
	my(%newsheaders, $newsbody);
	$newsheaders{'Author'} = $engine->argument('name');
	$newsheaders{'Author'} ||= $engine->{'AC'}
            if($engine->argument('email') =~ /^\s*$/);
	$newsheaders{'Title'} = $engine->argument('subject');
	$newsheaders{'Category'} = $engine->argument('category');
	$newsheaders{'Type'} = 'NEWS';
	$newsheaders{'Date'} = scalar(localtime);
	chomp($newsheaders{'Date'});
	if($engine->argument('email') =~ /\@/) {
	    $newsheaders{'Link'} = "<a href=\"mailto:" . 
		$engine->argument('email')
		    . "\">$newsheaders{Author}...?</a>";
	} elsif($engine->argument('email')) {
	    $newsheaders{'Link'} = "<a href=\"" . $engine->argument('email') .
		"\">$newsheaders{Author}...?</a>";
	} else {
	    $newsheaders{'Link'} = "$newsheaders{Author}...?";
	}
	
	if($ENV{REMOTE_USER} && ($ENV{REMOTE_USER} !~ /unknown/i)) {
	    $filedir = $engine->filename($engine->url('/@@NEWS@@/',
			     $engine->argument('channel') || 'general', '/'));
	    
	    $person = new CGI::WeT::User('username' => $ENV{REMOTE_USER});
	    $newsheaders{'Author'} = $person->{'familiarName'} || 
		$ENV{REMOTE_USER};
	    $newsheaders{'AuthenticatedAs'} = $ENV{REMOTE_USER};
	    if($$person{'mail'} !~ /^\s*$/) {
		$newsheaders{'Link'} = "<a href=\"mailto:$$person{'mail'}\">$$person{'familiarName'}</a>";
	    } elsif($$person{www_url} !~ /^\s*$/) {
		$newsheaders{Link} = "<a href=\"$$person{www_url}\">$$person{familiarName}</a>";
	    } else {
		$newsheaders{Link} = $$person{familiarName} || 
		    $ENV{REMOTE_USER};
	    }

	    $engine->print(<<1HERE1);
Thank you for your submission.  As an authenticated user, your story will
be available immediately.  Any corrections or retractions will need to be
made as responses to this item. The URL for this item is
<p>
<center><a href="$fileurl">http://$servername$fileurl</a></center>
1HERE1
    ;
	} else {
	    $filedir = $engine->filename($engine->url('@@NEWS@@/todo/',
			      $engine->argument('channel') || 'general', '/'));

	    $engine->print(<<1HERE1);
Thank you for your submission.  As an unauthenticated user, your story will
be available as soon as it is approved.
Any corrections or retractions will need to be
made as responses to this item. The URL for this item will be
<p>
<center><a href="$fileurl">http://$servername$fileurl</a></center>
1HERE1
    ;
	}
	# create news item
	$filedir =~ /([^;!\#]*)/;
	$filedir = $1;
	$filename =~ /([^;!\#]*)/;
	$filename = $1;
	&makeDirectories($filedir);
	open OUT, ">$filedir/$filename";
	print OUT map( "$_:$newsheaders{$_}\n", sort keys %newsheaders );
	print OUT "\n";
	print OUT $engine->smarttext($engine->argument('story'));
	close OUT;
    }
}
	
sub makeDirectories {
    my($dir) = @_;
    my(@dirs, $mydir);

    if(!-e $dir) {
        @dirs = split("/", $dir);
        while($dirs[0] =~ /^\s*$/) {
            shift @dirs;
        }
        $mydir = "/";
        while($#dirs > -1) {
            if(!-e $mydir) {
                mkdir($mydir, 0755) || die "Could not create $mydir";
                chmod(0755, $mydir);
            }
            $mydir .= "/" . shift @dirs;
        }
        if(!-e $mydir) {
            mkdir($mydir, 0755) || die "Could not create $mydir";
        }
    }
    -d $dir || die "It seems that $dir exists, but is not a directory.  This needs to be made a directory.\n";
}
