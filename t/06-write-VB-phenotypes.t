use Test::More tests => 1;

#
# will show output of diff if tested in verbose mode only
#


use Data::Dumper;
use Bio::Parser::ISATab;
use Text::CSV_XS;
use File::Path qw/rmtree/;

my $input_directory = 't/Test-data-01';
my $pheno_filename = 'p_IR_WHO.txt';

my $reader = Bio::Parser::ISATab->new(directory=>$input_directory);

my $pheno_custom_headings = Bio::Parser::ISATab::ordered_hashref();
$pheno_custom_headings->{'Phenotype Name'} = 'reusable node';
$pheno_custom_headings->{'Observable'} = 'attribute';
$pheno_custom_headings->{'Attribute'} = 'attribute';
$pheno_custom_headings->{'Value'} = 'attribute';

my $pheno_data = $reader->parse_study_or_assay($pheno_filename, undef, $pheno_custom_headings);

my $output_directory = './t/temp-output';
my $writer = Bio::Parser::ISATab->new(directory=>$output_directory);
$writer->write_study_or_assay($pheno_filename, $pheno_data, $pheno_custom_headings);

my $pheno_data2 = $writer->parse_study_or_assay($pheno_filename, undef, $pheno_custom_headings);

is_deeply($pheno_data2, $pheno_data, "reloaded $pheno_file data from dumped ISA-Tab is identical to original");

