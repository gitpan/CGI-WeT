# $Id: startup.pl,v 1.5 1999/04/28 02:50:10 jsmith Exp $
# This is used by Apache to load in all the different modules needed...

# the following script will load all the modules in the current distribution.
use CGI::WeT ();
use CGI::WeT::Theme::Loader::WeT ();
# use CGI::WeT::User::DBI::LDAP ();
# use CGI::WeT::Modules::News ();
# use CGI::WeT::Modules::Calendar ();

#
# The following are needed by CGI::WeT::User::DBI::LDAP
#  - they help it take data from LDAP to a common format
#  - and back.  if records in LDAP are not what we expect
#  - in the rest of the site, this is where we translate them.
#

sub CGI::WeT::User::DBI::LDAP::base {
    return 'ou=Department of Physics,o=Texas A&M University,st=TX,c=US';
}

sub CGI::WeT::User::DBI::LDAP::LDAPtofields {
    my $entry = shift;
    my $k;
    my $person = { };
    foreach $f ($entry->attributes) {
        $person->{$f} = join(' ', $entry->get($f));
        $person->{$f} =~ s{\\n}{\n}g;
        delete $person->{$f} if $person->{$f} =~ /^\s*$/;
    }

    $person->{'username'} = $person->{'cn'};
    if($person->{'mail'} =~ /\@tamu.edu$/) {
        $person->{'publicEmail'} = $person->{'mail'};
    } else {
        $person->{'publicEmail'} = $person->{'uid'} . '@physics.tamu.edu';
    }

    return $person;
}

sub CGI::WeT::User::DBI::LDAP::fieldstoLDAP {
    my $request = shift;

    if(exists $request->{'username'}) {
        $request->{'cn'} = $request->{'username'};
        delete $request->{'username'};
    }
}

#
# The following are for the calendar code
#

$CGI::WeT::Calendar::category = {
        'default' => {
            'required' => 'title date',
            'desired' => 'description starttime endtime url sponsor contact audience',
        },
        'coll' => {
            'name' => 'Colloquium',
            'required' => 'location starttime speaker sponsor',
        },
        'acad' => {
            'name' => 'Academic',
        },
        'admin' => {
            'name' => 'Administrative',
        },
        'dls' => {
            'name' => 'Distinguished Lecture Series',
            'required' => 'location starttime speaker sponsor',
        },
        'hldy' => {
            'name' => 'Holiday',
            'not-desired' => 'starttime endtime sponsor contact audience',
        },
        'leave' => {
            'name' => 'Leave/Vacation',
            'not-desired' => 'starttime endtime sponsor contact audience',
        },
        'rm426' => {
            'name' => 'Conference Room 426',
            'required' => 'contact',
        },
        'seminar' => {
            'name' => 'Seminar',
            'required' => 'location starttime speaker sponsor',
        },
        'social' => {
            'name' => 'Social',
            'required' => 'location starttime contact',
        },
    };

$CGI::WeT::Calendar::fields = {
        'title' => {
            'type' => 'text',
            'size' => '50',
            'name' => 'Title',
        },
        'description' => {
            'type' => 'area',
            'rows' => '10',
            'cols' => '60',
            'name' => 'Description',
        },
        'location' => {
            'type' => 'text',
            'size' => '50',
            'name' => 'Location',
        },
        'starttime' => {
            'type' => 'time',
            'name' => 'Start Time',
        },
        'endtime' => {
            'type' => 'time',
            'name' => 'End Time',
        },
        'url' => {
            'type' => 'text',
            'size' => '50',
            'name' => 'Event URL',
        },
        'date' => {
            'type' => 'date',
            'name' => 'Date',
        },
        'sponsor' => {
            'type' => 'text',
            'size' => '50',
            'name' => 'Sponsor',
        },
        'speaker' => {
            'type' => 'text',
            'size' => '50',
            'name' => 'Speaker',
        },
        'contact' => {
            'type' => 'text',
            'size' => '50',
            'name' => 'Contact',
        },
        'audience' => {
            'type' => 'text',
            'size' => '50',
            'name' => 'Audience',
        },
    };

1;

