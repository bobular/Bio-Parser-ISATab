use Test::More;

use Data::Dumper;
use Bio::Parser::ISATab;
use Text::CSV_XS;

#
# run with 'prove -l' (I always forget what it's called)
#

my $output_directory = './t/temp-output';

my $writer = Bio::Parser::ISATab->new(directory=>$output_directory);

plan tests => 1;

my $study =
  {
   sources =>
    {
     'source1' =>
     {
      characteristics => { site_type => { value => 'pond' } },
      samples => # level 1
      {
       dip1 =>
       {
	characteristics => { volume => { value => 100, unit => { value => 'ml' } } },
	material_type => { value => 'pond water' },
        samples => # level 2
	{
	 tadpoles =>
	 {
	  characteristics => { colour => { value => 'brown' } },
	  material_type => { value => 'specimen' },
	 },
	 larvae =>
	 {
	  characteristics => { colour => { value => 'yellow' } },
	  material_type => { value => 'specimen' },
	 },
	},
       },
       dip2 =>
       {
	characteristics => { volume => { value => 200, unit => { value => 'ml' } } },
	material_type => { value => 'pond water' },
       }
      }
     },
    }
  };


$writer->write_study_or_assay('s_MULTIPLE_SAMPLES.txt', $study, {});

my $parser = Bio::Parser::ISATab->new(directory=>$output_directory);

my $study2 = $parser->parse_study_or_assay('s_MULTIPLE_SAMPLES.txt');


is_deeply($study, $study2, "s_MULTIPLE_SAMPLES.txt read back identically");


