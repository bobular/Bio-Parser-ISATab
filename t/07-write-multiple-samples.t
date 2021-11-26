use Test::More;

use Data::Dumper;
use Bio::Parser::ISATab;
use Text::CSV_XS;

#
# run with 'prove' (I always forget what it's called)
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
	samples => # level 2
	{
	 tadpoles =>
	 {
	  characteristics => { colour => { value => 'brown' } }
	 },
	 larvae =>
	 {
	  characteristics => { colour => { value => 'yellow' } }
	 },
	},
       },
       dip2 =>
       {
	characteristics => { volume => { value => 200, unit => { value => 'ml' } } },
       }
      }
     },
    }
  };


$writer->write_study_or_assay('s_MULTIPLE_SAMPLES.txt', $study, {});


ok(-e 't/temp-output/s_MULTIPLE_SAMPLES.txt');

