# $Id: Makefile.PL 6 2005-03-27 15:37:39Z kentaro $

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'WebService::Hatena::Fotolife',
    VERSION_FROM      => 'lib/WebService/Hatena/Fotolife.pm',
    PREREQ_PM         => {
		XML::Atom   => 0.11,
		Image::Info => 0,
	},
);
