#
# $Id: User.pm,v 1.9 1999/05/14 01:13:06 jsmith Exp $
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

package CGI::WeT::User;

use strict;
use Carp;
use vars qw($VERSION);
use integer;

( $VERSION ) = '$Revision: 1.9 $ ' =~ /\$Revision:\s+([^\s]+)/;

=pod

=head1 NAME

CGI::WeT::User - User database interface for CGI::WeT

=head1 SYNOPSIS

    use CGI::WeT::User ();

=head1 DESCRIPTION

This module provides the CGI::WeT package with access to the user database
used for authentication.  This allows other scripts and modules to interact
with user information when pages have been authenticated.

To make full use of this module, one of the various CGI::WeT::User::DBI::*
modules must be compiled also. (Here CGI::WeT::User::DBI is not a reference
to the more well known DBI:: package though work is progressing on
CGI::WeT::User::DBI::DBI.)

CGI::WeT::User will query each available module under
CGI::WeT::User::DBI:: in turn until one returns a defined reference.  To
only use a particular database when several might be available, use the

    PerlSetVar WeT_UserDB <DBI Module>

configuration directive.  This will cause CGI::WeT::User to only query the
CGI::WeT::User::DBI::<DBI Module> module.

See the documentation for the particular database interface being used for more
requirements or configuration directives.

To retrieve information on a user, use the following call:

    $user = new CGI::WeT::User ($engine, 'username' => $ENV{'REMOTE_USER'});

where $engine is the CGI::WeT::Engine object being used to render the page.

=cut
    ;

sub new {
    my $class = shift;
    my $engine = shift;
    my $r;
    my $dbi;
    my $self = {};
    my(@query) = @_;

    $class = ref($class) || $class;

    if(@query == 0) {
	@query = ('username' => $ENV{'REMOTE_USER'});
    }

    unless(ref $engine) {
	if(defined $engine) {
	    unshift @query, $engine;
	}
	$engine = { };
    }
    
    return _do_query($class, $engine, 1, @query);
}

sub list {
    my $class = shift;
    my $engine = shift;
    my $self = {};
    my(@query) = @_;

    $class = ref($class) || $class;

    print "Getting a list of users...\n";

    if(@query == 0) {
        @query = ('username' => $ENV{'REMOTE_USER'});
    }

    unless(ref $engine) {
        if(defined $engine) {
            unshift @query, $engine;
        }
        $engine = { };
    }

    return _do_query($class, $engine, 2, @query);
}

sub _do_query {
    my $class = shift;
    my $engine = shift;
    my $maxfound = shift;
    my (@query) = @_;
    my $self;
    my $numfound = 0;
    my $r;
    my $dbi;
    
    if($engine->{'USER'}->{'DBI'}) {
	# query the last one that worked...
	my(@res) = $engine->{'USER'}->{'DBI'}->query(@query);
        if($maxfound == 1 && scalar(@res) == 1) {
            $self = $res[0];
            $numfound = 1;
        } elsif($maxfound != 1) {
            $self = [ @res ];
            $numfound = scalar(@res);
        }
    } elsif($engine->{'MOD_PERL'} &&
	    ($r = Apache->request) &&
	    ($dbi = $r->dir_config('WeT_UserDB'))) {
	no strict;
	$engine->{'USER'}->{'DBI'} =
	    &{ "CGI::WeT::User::DBI::$dbi\::new" }("CGI::WeT::User::DBI::$dbi");
	my(@res) = $engine->{'USER'}->{'DBI'}->query(@query);
        if($maxfound == 1 && scalar(@res) == 1) {
            $self = $res[0];
            $numfound = 1;
        } elsif($maxfound != 1) {
            $self = [ @res ];
            $numfound = scalar(@res);
        }
    } else {
	my(@res) = ();
	my(@dbis) = map(/(.*)::$/,
			keys %CGI::WeT::User::DBI::
			);
	while(@dbis && !@res) {
	    $dbi = shift @dbis;
	    no strict;
	    $engine->{'USER'}->{'DBI'} =
		&{ "CGI::WeT::User::DBI::$dbi\::new" }("CGI::WeT::User::DBI::$dbi");
	    my(@res) = $engine->{'USER'}->{'DBI'}->query(@query);
	}
        if($maxfound == 1 && scalar(@res) == 1) {
            $self = $res[0];
            $numfound = 1;
        } elsif($maxfound != 1) {
            $self = [ @res ];
            $numfound = scalar(@res);
        }
    }
    
    return undef unless $numfound > 0;

    foreach my $person ($maxfound == 1 ? ($self) : (@$self)) {
	$person->{'CONNECTION'} = $engine->{'USER'}->{'DBI'};
	if(defined $person->{'gn'}) {
	    my $nname;
	    if(ref $person->{'gn'}) {
		$nname = $person->{'gn'}->[0];
	    } else {
		$nname = $person->{'gn'};
	    }
	    if(defined $person->{'sn'}) {
		$nname .= " ";
		if(ref $person->{'sn'}) {
		    $nname .= $person->{'sn'}->[0];
		} else {
		    $nname .= $person->{'sn'};
		}
		$person->{'familiarName'} = $nname;
	    } else {
		my $name;
		if(ref $person->{'cn'}) {
		    $name = $person->{'cn'}->[0];
		} else {
		    $name = $person->{'cn'};
		}
		my @names = split(/\s+/, $name);
		pop(@names) if ($names[$#names] =~ /^I+$/i);
		pop(@names) if ($names[$#names] =~ /^[js]r$/i);
		$person->{'familiarName'} = "$nname $names[$#names]";
	    }
	} elsif(ref $person->{'cn'}) {
	    $person->{'familiarName'} = $person->{'cn'}->[0];
	} else {
	    $person->{'familiarName'} = $person->{'cn'};
	}

	bless $person, $class;
    }
    return $self;
}

sub default {
    my $class = shift;
    my $engine = shift;
    my $self = {};

    $self->{'familiarName'} = $engine->{'AC'};
    $self->{'groups'} = '';
    $self->{'name'} = $engine->{'AC'};

    bless $self, $class;
    return $self;
}

sub allowed {
    my $self = shift;
    my $groups = scalar($self->get('groups'));

    return 0 if(defined $CGI::WeT::User::silentgroup &&
		$groups =~ /\b\Q$CGI::WeT::User::silentgroup\b/);
    
    return 1 if(defined $CGI::WeT::User::supergroup &&
		$groups =~ /\b\Q$CGI::WeT::User::supergroup\b/);

    foreach (grep(exists $CGI::WeT::User::groups{$_}, @_)) {
	return 0 if $groups !~ /\b\Q$_\b/;
    }

    return 1;
}

sub attributes {
    my $self = shift;

    return grep(/^[a-z]/, keys %$self);
}

sub get {
    my $self = shift;
    my $key = shift;
    
    if(wantarray) {
	if(ref($self->{$key})) {
	    return (@ { $self->{$key} });
	} else {
	    return ($self->{$key});
	}
    } else {
	if(ref($self->{$key})) {
	    return join(' ', @ { $self->{$key} });
	} else {
	    return $self->{$key};
	}
    }
}
1;
