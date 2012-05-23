use Test::More tests => 1;
use Data::Dumper;

use Bio::Parser::ISATab;

my $parser = Bio::Parser::ISATab->new(directory=>'./t/BII-S-6');
my $isa = $parser->parse;

# this path ends in an empty hash (but if there had been a comment column in the ISA-Tab, it would be non-empty
is_deeply($isa->{studies}[0]{study_assays}[0]{samples}{'ro.Group-2.Subject-3.BTO:liver'}{acquisition_parameter_data_files}{'some file.txt'}{nmr_assays}{'NMR-MAS-Assay31'}{free_induction_decay_data_files}{'JGHk3do3.MAS_1_1'}{data_transformations}{'Bucketing-MAS'}{derived_spectral_data_files}{'BII-S-6-bucketed-masall.txt'}{metabolite_assignment_files}{'identified-metabolites2.txt'}, { });


$Data::Dumper::Indent = 1;
# diag(Dumper($isa));
