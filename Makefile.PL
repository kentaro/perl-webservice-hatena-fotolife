use inc::Module::Install;
use Module::Install::ReadmeMarkdownFromPod;

name     'WebService-Hatena-Fotolife';
author   'Kentaro Kuribayashi, <kentarok@cpan.org>';
license  'MIT';
all_from 'lib/WebService/Hatena/Fotolife.pm';

readme_markdown_from 'lib/WebService/Hatena/Fotolife.pm';

requires 'XML::Atom' => '0.11';
requires 'Image::Info';

test_requires 'Test::More' => 0.96;

repository 'http://github.com/kentaro/perl-webservice-hatena-fotolife';
bugtracker 'http://github.com/kentaro/perl-webservice-hatena-fotolife/issues';

auto_include_deps;
WriteAll;
