#
# sitemap for Plain theme
#

#
# This is an example of a fairly large sitemap.  This is taken from the
# author's site though it is a bit out of date.
#

sub CGI::WeT::Theme::Loader::WeT::Plain::SiteMap {
    return {
	'Coding Fun' => {
	    'location' => '/jsmith/code.cgi/',
	    'help' => 'Various C/C++ routines written through the years',
	},    
	'Animation' => {
	    'location' => '/jsmith/mpegs/',
	    'help' => 'Sunset animations',
	},
	'GNOME' => {
	    'location' => '/jsmith/gnome/',
	    'help' => 'GNOME projects and resources',
	    'content' => {
		'GNOMEBook' => {
		    'location' => '/jsmith/gnome/GNOMEBook/',
		    'help' => 'GNOME document oriented interface',
		    'content' => {
			'Config File Format' => {
			    'location' => '/jsmith/gnome/GNOMEBook/config.thtml',
			    'help' => 'GNOMEBook configuration',
			},
			'Document Methods' => {
			    'location' => '/jsmith/gnome/GNOMEBook/documentmethods.thtml',
			    'help' => 'How methods are defined for document types',
			},
			'File Format' => {                        
			    'location' => '/jsmith/gnome/GNOMEBook/fileformat.thtml',
			    'help' => 'File format for a GNOMEBook',
			},
			'Protocols' => {
			    'location' => '/jsmith/gnome/GNOMEBook/protocols.thtml',
			    'help' => 'How methods are defined for various protocols',
			},
			'Source Code' => {
			    'location' => '/jsmith/gnome/GNOMEBook/source.thtml',
			    'help' => 'Current source for GNOMEBook',
			},
			'User Interface' => {
			    'location' => '/jsmith/gnome/GNOMEBook/userinterface.thtml',
			    'help' => 'Design of the user interface',
			},
		    },
		},
		'GNOME Particle Simulator' => {
		    'location' => '/jsmith/gnome/gps/',
		    'help' => 'GNOME Particle Simulator and user interface',
		    'content' => {
			'Computational Methodology' => {
			    'location' => '/jsmith/gnome/gps/comp_methods.thtml',
			    'help' => 'Design of the system',
			},
			'Return Codes' => {
			    'location' => '/jsmith/gnome/gps/errors.thtml',
			    'help' => 'Simulator return codes per the protocol',
			},
			'Source Code' => {
			    'location' => '/jsmith/gnome/gps/source.thtml',
			    'help' => 'Latest GPSui source code',
			},
		    },
		},
	    },
	},
	'mod_auth_ns.c' => {
	    'location' => '/jsmith/mod_auth_ns.thtml',
	    'help' => 'Apache authentication module for PH',
	},
	'Music' => {
	    'location' => '/jsmith/music/',
	    'help' => 'CD collection details',
	    'content' => {
		'CD List' => {
		    'location' => '/jsmith/music/cdlist.cgi',
		    'help' => 'Listing of CDs in the database',
		},
		'Composers' => {
		    'location' => '/jsmith/music/index.cgi',
		    'help' => 'Listing of composers',
		},
	    },
	},
	'R&#233;sum&#233;' => {
	    'location' => '/jsmith/resume.thtml',
	    'help' => 'Portfolio for Jim Smith',
	},
	'Pictures' => {
	    'location' => '/jsmith/picts/',
	    'help' => 'Photography and the GIMP',
	},
	'Writing' => {
	    'location' => '/jsmith/writing/',
	    'content' => {
		'Free Speech' => {
		    'location' => '/jsmith/speech.thtml',
		    'help' => 'Me spouting forth',
		},
		'Short Stories' => {
		    'location' => '/jsmith/writing/short-stories/',
		},
	    },
	},
	'WeT Perls' => {
	    'location' => '/jsmith/wet-perls/',
	    'content' => {
		'keys' => 'Source|Themes|ToDo List|WeT Perls License|Modules License',
		'WeT Perls License' => {
		    'location' => '/jsmith/wet-perls/copying.thtml',
		},
		'Modules License' => {
		    'location' => '/jsmith/wet-perls/copying.lib.thtml',
		},
		'Modules' => {
		    'location' => '/jsmith/wet-perls/modules/',
		    'content' => {
			'Navigation' => {
			    'location' => '/jsmith/wet-perls/modules/navigation.thtml',
			},
		    }
		},
		'Reference' => {
		    'location' => '/jsmith/wet-perls/reference/',
		    'content' => {
			'Modules' => {
			    'location' => '/jsmith/wet-perls/reference/modules/',
			    'content' => {
				'HBOX' => {
				    'location' => '/jsmith/wet-perls/reference/modules/hbox.thtml',
				},
				'VBOX' => {
				    'location' => '/jsmith/wet-perls/reference/modules/vbox.thtml',
				},
				'LINE' => {
				    'location' => '/jsmith/wet-perls/reference/modules/line.thtml',
				},
			    },
			},
		    },
		},
		'Source' => {
		    'location' => '/jsmith/wet-perls/source.thtml',
		},
		'Themes' => {
		    'location' => '/jsmith/wet-perls/themes/',
		    'content' => {
			'Creating a Theme' => {
			    'location' => '/jsmith/wet-perls/themes/creating.thtml'
			    },
			    },
			    },
				'ToDo List' => {
				    'location' => '/jsmith/wet-perls/todo.thtml',
				},
	    },
	},
	'Web Guide' => {
	    'location' => '/jsmith/web_guide/',
	    'help' => 'TAMU Physics web design goals',
	    'content' => {
		'Apache' => {
		    'location' => '/jsmith/web_guide/mod_auth_ns.thtml',
		    'help' => 'How Apache has been modified for the TAMU Physics web site',
		},
		'Future Projects' => {
		    'location' => '/jsmith/web_guide/projects/',
		    'help' => 'Various projects underway',
		    'content' => {
			'RCS System' => {
			    'location' => '/jsmith/web_guide/projects/rcs.thtml',
			    'help' => 'Thoughts on using CVS to manage web material',
			},
			'Web Themes' => {
			    'location' => '/jsmith/web_guide/projects/themes.thtml',
			    'help' => 'Thoughts on themifying the web site',
			},
		    },
		},
	    },
	},
    };
}

1;
