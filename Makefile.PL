use inc::Module::Install;

name     'WebService-Hatena-Fotolife';
author   'Kentaro Kuribayashi, <kentarok@cpan.org>';
license  'Perl';
all_from 'lib/WebService/Hatena/Fotolife.pm';

requires 'XML::Atom' => '0.11';
requires 'Image::Info';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
WriteAll;
