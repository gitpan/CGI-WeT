#! /usr/bin/perl

use strict;

my $engine = new CGI::WeT::Engine;

$engine->headers_push('Title' => 'News');

my($dir) = $engine->filename($engine->url('@@NEWS@@', '/',
                             $engine->argument('channel') || 'general'));

my(@files);
my($file, $headers, $key, $val, $url, $header);

if(-e $dir && opendir(OD, $dir)) {
    my $category = $engine->argument('category');
    (@files) = sort grep(/^\d/ && /($category|\.)\.thtml$/, readdir(OD));    closedir OD;
} else {
    $engine->body_push("Unable to find news items for the ",                       $engine->argument('channel') || 'general',
                       " channel.");
    $dir = $engine->filename($engine->url('@@NEWS@@'));
    if(opendir(OD, $dir)) {
        $engine->body_push("The following are avaiable:<ul>");
        foreach (sort grep(!/^\./ && -d "$dir/$_", readdir(OD))) {
            $engine->body_push("<li><a href=\"",
                               $engine->url('@@NEWS@@/index.cgi',
                                            "?channel=$_"),
                               "\">$_</a>");
        }
        $engine->body_push("</ul>");
   }
}

if($engine->argument('number') && $engine->argument('number') < @files) {
    @files = splice(@files, -$engine->argument('number'));
}

while(@files) {
    $file = pop @files;
    $headers = {};

    open IN, "<$dir/$file";
    while(<IN>) {
        last if /^\s*$/;
        next if /^\s*#/;
        chomp;
        if(/^[A-Za-z_]+:/) {
            ($key, $val) = split(/\s*:\s*/,$_,2);
        } else {
            $val = " $_";
        }
        $$headers{$key} .= $val;
    }
    close IN;

    $url = $engine->url('@@NEWS@@/', $engine->argument('channel') || 'general',
                        '/', $file);

    $engine->body_push("<strong><a href=\"$url\">$$headers{Title}</a></strong>");

    $engine->body_push(" by $$headers{Link}") if $$headers{'Link'};
    $engine->body_push("<br><br>");
}

print "Content-type: text/html\n\n", $engine->render_page;

