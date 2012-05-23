use Test::More tests => 10;
use Data::Dumper;

use Bio::Parser::ISATab;

my $parser = Bio::Parser::ISATab->new(directory=>'./t/BII-S-6');

#
# pooling test
#
my $sources = $parser->parse_study_or_assay('../misc-test-files/s_pool_test.txt');

# both are purple
is($sources->{sources}{source1}{samples}{pool1}{characteristics}{colour}{value}, 'purple');
is($sources->{sources}{source2}{samples}{pool1}{characteristics}{colour}{value}, 'purple');

# this change...
$sources->{sources}{source1}{samples}{pool1}{characteristics}{colour}{value} = 'green';
# ...should affect the same sample accessed via the other source:
is($sources->{sources}{source2}{samples}{pool1}{characteristics}{colour}{value}, 'green', 'should be green');

# diag(Dumper($sources));

# now a bigger test on some 'real' data

my $isa = $parser->parse;

is($isa->{studies}[0]{sources}{'ro.Group-12.Subject-3'}{characteristics}{'strain'}{value}, 'Wistar rats');
is($isa->{studies}[0]{sources}{'ro.Group-12.Subject-3'}{characteristics}{'strain'}{term_source_ref}, 'NEWT');
is($isa->{studies}[0]{sources}{'ro.Group-12.Subject-3'}{characteristics}{'strain'}{term_accession_number}, 10116);

is($isa->{studies}[0]{sources}{'ro.Group-12.Subject-3'}{protocols}{'P-BMAP-1'}{parameter_values}{dose}{value}, 150);
is($isa->{studies}[0]{sources}{'ro.Group-12.Subject-3'}{protocols}{'P-BMAP-1'}{parameter_values}{dose}{unit}{value}, 'mg/kg/day'); # no UO term in this case

# samples

is($isa->{studies}[0]{sources}{'ro.Group-8.Subject-2'}{samples}{'ro.Group-8.Subject-2.BTO:liver'}{characteristics}{'organism part'}{value}, 'liver');


#
# check sources are in order
#

is(join('', map "$_\n", keys %{$isa->{studies}[0]{sources}}), <<'EOF', "sources are in order");
ro.Group-1.Subject-1
ro.Group-1.Subject-2
ro.Group-1.Subject-3
ro.Group-2.Subject-1
ro.Group-2.Subject-2
ro.Group-2.Subject-3
ro.Group-3.Subject-1
ro.Group-3.Subject-2
ro.Group-3.Subject-3
ro.Group-4.Subject-1
ro.Group-4.Subject-2
ro.Group-4.Subject-3
ro.Group-5.Subject-1
ro.Group-5.Subject-2
ro.Group-5.Subject-3
ro.Group-6.Subject-1
ro.Group-6.Subject-2
ro.Group-6.Subject-3
ro.Group-7.Subject-1
ro.Group-7.Subject-2
ro.Group-7.Subject-3
ro.Group-8.Subject-1
ro.Group-8.Subject-2
ro.Group-8.Subject-3
ro.Group-9.Subject-1
ro.Group-9.Subject-2
ro.Group-9.Subject-3
ro.Group-10.Subject-1
ro.Group-10.Subject-2
ro.Group-10.Subject-3
ro.Group-11.Subject-1
ro.Group-11.Subject-2
ro.Group-11.Subject-3
ro.Group-12.Subject-1
ro.Group-12.Subject-2
ro.Group-12.Subject-3
ro.Group13.Subject-1
ro.Group13.Subject-2
ro.Group13.Subject-3
ro.Group14.Subject-1
ro.Group14.Subject-2
ro.Group14.Subject-3
ro.Group15.Subject-1
ro.Group15.Subject-2
ro.Group15.Subject-3
ro.Group16.Subject-1
ro.Group16.Subject-2
ro.Group16.Subject-3
ro.Group17.Subject-1
ro.Group17.Subject-2
ro.Group18.Subject-1
ro.Group18.Subject-2
ro.Group18.Subject-3
ro.Group-10.Subject-4
EOF

$Data::Dumper::Indent = 1;
#diag(Dumper($isa));
