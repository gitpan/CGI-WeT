# startup.pl
# This is used by Apache to load in all the different modules needed...

# the following script will load all the modules in the current distribution.
use CGI::WeT::Engine ();
use CGI::WeT::User ();
use CGI::WeT::User::DBI::LDAP ();
use CGI::WeT::Theme ();
use CGI::WeT::Theme::Loader::WeT ();
use CGI::WeT::Modules::Basic ();
use CGI::WeT::Modules::News ();

#
# The following are needed by CGI::WeT::User::DBI::LDAP
#  - they help it take data from LDAP to a common format
#  - and back.  if records in LDAP are not what we expect
#  - in the rest of the site, this is where we translate them.
#

sub CGI::WeT::User::DBI::LDAP::LDAPtofields {
    my $entry = shift;
    my $k;
    my $person = { };
    my @fields = qw(uid gn sn cn mail);
    foreach $f (@fields) {
        $person->{$f} = $entry->get($f);    }

    $person->{'username'} = $person->{'uid'};

    return $person;
}

sub CGI::WeT::User::DBI::LDAP::fieldstoLDAP {
    my $request = shift;

    if(exists $request->{'username'}) {
        $request->{'uid'} = $request->{'username'};
        delete $request->{'username'};
    }
}

1;
