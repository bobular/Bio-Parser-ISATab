use Test::More tests => 7;
use Data::Dumper;
$Data::Dumper::Indent = 1;

use Bio::Parser::ISATab;

my $parser = Bio::Parser::ISATab->new(directory=>'./t/BII-S-6');
my $isa = $parser->parse;

# this path ends in an empty hash (but if there had been a comment column in the ISA-Tab, it would be non-empty
# diag(Dumper($isa->{studies}[0]{study_assays}[0]{samples}{'ro.Group-2.Subject-3.BTO:liver'}));
# this is also actually testing the missing extracts (well, extract names) at the end of a_griffin-assay-Mx.txt
is_deeply($isa->{studies}[0]{study_assays}[0]{samples}{'ro.Group-2.Subject-3.BTO:liver'}{nmr_assays}{'NMR-MAS-Assay31'}{free_induction_decay_data_files}{'JGHk3do3.MAS_1_1'}{data_transformations}{'Bucketing-MAS'}{derived_spectral_data_files}{'BII-S-6-bucketed-masall.txt'}{metabolite_assignment_files}{'identified-metabolites2.txt'}, { });

# diag(Dumper($isa));


# now load a custom assay file with extra columns "Amazingness" and "Coolness" analagous to "Material Type" and "Label"

my $custom = $parser->parse_study_or_assay('../misc-test-files/a_custom-cols.txt', $isa,
					   {
					    'Amazingness' => 'attribute',
					    'Coolness' => 'attribute',
					    'Widget Name' => 'reusable node',
					    'Institution Name' => 'non-reusable node',
					   });


#diag(Dumper($custom));
#diag(Dumper($custom->{samples}{'sample zero'}));


is_deeply($custom->{samples}{'sample zero'}{assays}{'AssayX'}{amazingness},
	  {
	   'value' => 'lots',
	   'term_source_ref' => 'PATO',
	   'term_accession_number' => '0012345'
	  },
	  "loaded Amazingness and term stuff");

is($custom->{samples}{'sample zero'}{assays}{'AssayX'}{coolness}{value}, 'little', "loaded Coolness");

ok(!exists $custom->{samples}{'sample zero'}{assays}{'AssayX'}{sickness}, "shouldn't load Sickness column");


is_deeply($custom->{samples}{'sample zero'}{assays}{'AssayX'}{institutions}{Anonymous}{widgets},
	  {
	   WidgetZ => {
		       coolness => { value => 'sub-zero' },
		       comments => { feedback => 'could do better' },
		      }
	  },
	  "test reusable node custom column");

isnt($custom->{samples}{'sample zero'}{assays}{'AssayX'}{institutions}{Anonymous},
     $custom->{samples}{'sample one'}{assays}{'AssayY'}{institutions}{Anonymous},
     "did not re-use institution node");

# now test performers and dates (only after Protocol REFs)

my $performer = $parser->parse_study_or_assay('../misc-test-files/a_performer-date.txt', $isa);

#diag(Dumper($performer));

is_deeply($performer->{samples}{'sample zero'}{assays}{AssayX}{protocols},
	  {
	   'MYPROTO' => {
			 'performer' => 'Bob',
			 'date' => '2000-01-01',
			 'parameter_values' => {
						'food' => {
							   'value' => 'toast'
							  }
					       }
			}
	  },
	  "load protocols with performer, date and parameter value"
	 );
