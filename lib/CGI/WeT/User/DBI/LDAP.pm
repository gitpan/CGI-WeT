#
# $Id: LDAP.pm,v 1.6 1999/05/14 01:13:06 jsmith Exp $
#
# Author: James G. Smith, Aaron Du Mar
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
# The author may be reached at <jsmith@nostrum.com>
#

package CGI::WeT::User::DBI::LDAP;

use Net::LDAP ();
use strict;
use Carp;

use vars qw($VERSION);

( $VERSION ) = '$Revision: 1.6 $ ' =~ /\$Revision:\s+([^\s]+)/;

=pod

=head1 NAME

CGI::WeT::User::DBI::LDAP - interface between CGI::WeT::User and Net::LDAP

=head1 SYNOPSIS

    use CGI::WeT::User::DBI::LDAP ();

=head1 DESCRIPTION

This package provides CGI::WeT::User with access to an LDAP database.  This
module requires B<Net::LDAP>.  Use of another LDAP package should only require
trivial changes to the code.

Three variables are required in the Apache configuration file (httpd.conf or
equivalent).

=over 4

=item PerlSetVar WeT_UserDB_LDAP_Host <host>

=item PerlSetVar WeT_UserDB_LDAP_Service <port>

=item PerlSetVar WeT_UserDB_LDAP_Base <base_dn>

=back 4

=cut

sub new {
    my($this, $host, $service) = @_;
    my($class) = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    my $r;

    if($ENV{'MOD_PERL'}) {
	$r = Apache->request;
	$host ||= $r->dir_config('WeT_UserDB_LDAP_Host');
	$service ||= $r->dir_config('WeT_UserDB_LDAP_Service');
    }

    $host ||= 'localhost';
    $service ||= '389';

    $host =~ /([-A-Za-z0-9\.]*)/;
    $host = $1;

    $service =~ /([-A-Za-z0-9\.]*)/;
    $service = $1;

    $$self{'host'} = $host;
    $$self{'service'} = $service;

    initialize($self);
    
    return $self;
}

sub initialize {
    my $self = shift;

    $$self{'connection'} ||= new Net::LDAP($$self{'host'},
					   'port' => $$self{'service'})
	or croak $@;
}

sub DESTROY {
    my $self = shift;
    
    $self->{'connection'}->unbind() if(defined $self->{'connection'});
    delete $self->{'connection'};
}

sub query {
    my $self = shift;
    my(%request) = @_;

    my($res, $entry, $r, $base);
    my(@res);

    if(defined &CGI::WeT::User::DBI::LDAP::fieldstoLDAP) {
	&CGI::WeT::User::DBI::LDAP::fieldstoLDAP(\%request);
    }

    my($filter) = join(",",
		       map(
                           "$_=$request{$_}", keys %request
                           )
                       );
    
    if($ENV{'MOD_PERL'} &&
       ($r = Apache->request)) {
	$base = $r->dir_config('WeT_UserDB_LDAP_Base');
    } else {
	$base = &CGI::WeT::User::DBI::LDAP::base();
    }

    $$self{'connection'} -> bind();
    $res = $self->{'connection'}->search(
					 base => $base,
					 filter => $filter
					 ) or croak $@;
    $self->{'connection'}->unbind();
    
    foreach $entry ($res->all_entries) {
	my($person, $f);
	
	$person = &CGI::WeT::User::DBI::LDAP::LDAPtofields($entry);
	$person -> {'name'} =
	    (split /,\s*/, (split /=\s*/,$entry->dn,2)[1], 2)[0];
	push(@res, $person);
    }

    return @res;
}
