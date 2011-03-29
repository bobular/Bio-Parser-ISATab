use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bio::Parser::ISATab',
    license             => 'perl',
    dist_author         => q{Bob MacCallum <r.maccallum@imperial.ac.uk>},
    dist_version_from   => 'lib/Bio/Parser/ISATab.pm',
    requires => {
	'Text::CSV_XS' => 1,
    },	
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Bio-Parser-ISATab-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
