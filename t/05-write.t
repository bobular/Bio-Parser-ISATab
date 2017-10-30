use Test::More tests => 3;

#
# will show output of diff if tested in verbose mode only
#


use Data::Dumper;
use Bio::Parser::ISATab;
use Text::CSV_XS;
use File::Path qw/rmtree/;


foreach my $input_directory ('./t/Test-data-01', './t/BII-S-6', './t/Investigation-Study-Comments') {

  diag "starting $input_directory\n";
  my $output_directory = './t/temp-output';

  my $reader = Bio::Parser::ISATab->new(directory=>$input_directory);
  my $isatab = $reader->parse;

  my $writer = Bio::Parser::ISATab->new(directory=>$output_directory);
  $writer->write($isatab);

  my $isatab2 = $writer->parse;
  is_deeply($isatab2, $isatab, "reloaded $input_directory ISA-Tab data from dumped ISA-Tab is identical to original");

  # rmtree($output_directory);

}



# TO DO - test the other directories



