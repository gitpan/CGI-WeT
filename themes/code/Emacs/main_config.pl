#
# $Id: main_config.pl,v 1.4 1999/04/12 00:13:48 jsmith Exp $ 
#    for the Emacs theme
#

sub CGI::WeT::Theme::Loader::WeT::Emacs::Init {
    my $body = {
	'bgcolor' => '000000',  # black
	'text' => 'f5deb3',     # wheat
	'alink' => 'f5f5f5',    # whitesmoke
	'vlink' => 'e9967a',    # darksalmon
	'link' => 'ff0000',     # red
    };
    my $css = [<<1HERE1];
A { text-decoration: none; }
P { text-align: justify; text-indent: 2em; font-size: medium;
    font-family: serif; top: 0px; bottom: 0px; }
1HERE1


    return {
	'STANDARD_PAGE' => {
	    'LAYOUT' => [
			 [
			  [
			   [
			    '<font color="#90b0ff">',
			    '[HEADERS key=Title]',
			    '</font>',
			    ],
			   '[VBOX colspan=2 bgcolor=182828]',
			   ],
			  '[LINE]',
			  [
			   [
			    '[NAVIGATION level=current type=text join=&nbsp; top=Home up=Up]',
			    '<hr>',
			    ],
			   '[VBOX colspan=2 valign=top]',
			   ],
			  '[LINE]',
			  [
			   [
			    '<small>',
			    '<strong>News Headlines</strong>',
			    [
			     '<br>', '[CONTENT]', '<br>',
			     '[POP]', '[POP]', '[POP]'
			     ],
			    '[NEWS_SUMMARY number=5 link=title]',
			    '<br><br><strong>Choose a theme:</strong>',
			    '[THEME_CHOOSER type=list join=<br>]',
			    '</small>',
			    ],
			   '[VBOX width=100]',
			   [
			    '[CONTENT]',
			    ],
			   '[VBOX width=*]',
			   ],
			  '[LINE]',
			  [
			   [
			    '<font color="#2f4f4f">',
			    '[NAVPATH join=/ ellipses=... depth=4 type=text]',
			    '</font>'
			    ],
			   '[VBOX bgcolor=7f735e colspan=2]', # f5deb3
			   ],
			  '[LINE]',
			  [
			   [
			    'Copyright &copy; 1999 Someone<br>',
			    ],
			   '[VBOX colspan=2]',
			   ],
			  '[LINE]',
			  ],
			 '[HBOX width=100%25 cellpadding=0 cellspacing=0 bgcolor=2f4f4f border=0]',
			 ]
			 },
	'DEFAULT' => {
	    'BODY' => $body,
	    'CSS' => $css,
	    'LAYOUT' => [
			 [ '[BODY]' ],
			 '[STANDARD_PAGE]',
			 ]
			 },
        'NEWS' => {
	    'BODY' => $body,
	    'CSS' => $css,
	    'LAYOUT' => [
			 [
			  '<small>',
			  '[HEADERS key=Date]',
			  ' ',
			  '[HEADERS key=Link]',
			  '</small><br><br>',
			  '[BODY]',
			  '<br><br><small><center>',
			  [ '&lt; ' ],
			  '[NEWS_NEXT type=story sequence=prev]',
			  [ ' contribute ' ],
			  '[LINK location=/@@NEWS@@/contribute.form.cgi]',
			  [ ' contribute (auth) ' ],
			  '[LINK location=/@@NEWS@@/contribute.form.private.cgi]',
			  [ ' &gt;' ],
			  '[NEWS_NEXT type=story sequence=next]',
			  '</center></small>',
			  ],
			 '[STANDARD_PAGE]',
			 ],
	},
			 };
}

1;
