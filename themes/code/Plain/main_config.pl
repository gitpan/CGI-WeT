#
# main_config for the Plain theme
#

sub CGI::WeT::Theme::Loader::WeT::Plain::Init {
    my $body = { };
    my $css  = [ ];

    return {
        'DEFAULT' => {
            'BODY' => $body,
            'CSS' => $css,
            'LAYOUT' => [
                         [ '[BODY]' ],
                         '[STANDARD_PAGE]',
			 ]
			 },
        'FRONT_PAGE' => {
            'BODY' => $body,
            'CSS' => $css,
            'LAYOUT' => [
                         [
                          [
                           '<strong><big>',
			   '[CONTENT]',
			   '</big></strong><br>',
			   '<small>', '[CONTENT]', '</small><p>',
			   '[POP]',
			   '[CONTENT]', '<br><br>',
			   ],
			  '[NEWS_SUMMARY number=10]',
			  '<p><hr><p>',
			  '[BODY]',
			  ],
			 '[STANDARD_PAGE]',
			 ]
			 },
        'NEWS' => {
	    'BODY' => $body,
            'CSS' => $css,
	    'LAYOUT' => [
			 [
			  '<center>[ ',
			  [ 'Previous Item |' ],
			  '[NEWS_NEXT sequence=prev type=story]',
			  [ ' Authenticated Contribute '],
			  "[LINK location=@@NEWS@@/contribute.private.cgi]",
			  [ '| Next Story ' ],
			  '[NEWS_NEXT sequence=next type=story]',
			  ']</center><p>',
			  'Entered on ',
			  '[HEADERS key=Date]',
			  '<p>',
			  '[BODY]',
			  ],
			 '[STANDARD_PAGE]',
			 ]
                     },
        'STANDARD_PAGE' => {
	    'BODY' => $body,
            'CSS' => $css,
	    'LAYOUT' => [
			 [
			  '[HEADERS key=Title]',
			  ],
			 '[HEADER]',
			 '[NAVBOX]',
			 '<BR>',
			 '[CONTENT]',
			 '<BR>',
			 [
			  'This site is themed with <a href="http://people.physics.tamu.edu/jsmith/wet-perls/">CGI::WeT</a>.  This is a Lynx friendly theme (minimal use of tables).'
			  ],
			 '[ABOUT]',
			 '[NAVBOX]',
			 [
			  'Email: <a href="mailto:your_email">your_email</a>'
			  ],
			 '[CONTACT]'
			 ],
			 },
        'HEADER' => {
	    'LAYOUT' => [
			 '<center><h1>',
			 '[CONTENT]',
			 '</center></h1>'
			 ],
			 },
        'NAVBOX' => {
	    'LAYOUT' => [
			 '[NAVIGATION type=text join=| level=current up=yes top=yes begin=[ end=] align=center]'
			 ],
			 },
        'CONTACT' => {
	    'LAYOUT' => [
			 '<hr><address>',
			 '[CONTENT]',
			 '</address>',
			 ],
	    },
        'ABOUT' => {
	    'LAYOUT' => [
			 '<h2>About Themes</h2>',
			 '[CONTENT]',
			 '<br>',
			 '[THEME_CHOOSER join=%20 style=list]'
			 ],
			 },
			 };
}

1;

