use Test::More;

#
# will show output of diff if tested in verbose mode only
#


use Data::Dumper;
use Bio::Parser::ISATab;
use Text::CSV_XS;
use File::Path qw/rmtree/;

my @defaults = ('./t/Test-data-01', './t/BII-S-6', './t/Investigation-Study-Comments');


my @input_directories = @ARGV;
@input_directories = @defaults unless (@input_directories);

plan tests => scalar @input_directories;

foreach my $input_directory (@input_directories) {

  diag "starting $input_directory\n";
  my $output_directory = './t/temp-output';

  my $reader = Bio::Parser::ISATab->new(directory=>$input_directory);
  my $isatab = $reader->parse;


  my $writer = Bio::Parser::ISATab->new(directory=>$output_directory);
  $writer->write($isatab);

  my $isatab2 = $writer->parse;

#warn Dumper($isatab->{studies}[0]{study_contacts});
#warn Dumper($isatab2->{studies}[0]{study_contacts});

  is_deeply($isatab2, $isatab, "reloaded $input_directory ISA-Tab data from dumped ISA-Tab is identical to original");

  # rmtree($output_directory);

}



# TO DO - test the other directories



