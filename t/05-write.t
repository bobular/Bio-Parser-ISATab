use Test::More tests => 1;

#
# will show output of diff if tested in verbose mode only
#


use Data::Dumper;
use Bio::Parser::ISATab;
use Text::CSV_XS;

my $input_directory = './t/BII-S-6';
my $output_directory = './t/temp-output';

my $reader = Bio::Parser::ISATab->new(directory=>$input_directory);
my $isatab = $reader->parse;

my $writer = Bio::Parser::ISATab->new(directory=>$output_directory);
$writer->write($isatab);

my $isatab2 = $writer->parse;

is_deeply($isatab2, $isatab, "reloaded ISA-Tab data from dumped ISA-Tab is identical to original");


# foreach my $filename (text_files_in_directory($input_directory)) {
# 
#   my $output_file = "$output_directory/$filename";
#   # special case for investigation file because its name is not specified in the ISA-Tab files themselves.
#   $output_file = "$output_directory/i_investigation.txt" if ($filename =~ /^i_/);
# 
#   ok(-f $output_file, "input $filename has existent output: $output_file");
# 
#   my @differences = compare_tsv("$input_directory/$filename", $output_file);
#   is(scalar @differences, 0, "content of $filename is identical");
#   if (-f $output_file && @differences) {
#     note(@differences);
#   }
# }
# 



# TO DO - test the other directories



sub text_files_in_directory {
  my ($dir) = @_;
  opendir(my $dh, $dir) || die "Can't opendir $dir: $!";
  my @files = grep { -f "$dir/$_" } readdir($dh);
  closedir $dh;
  return @files;
}


sub compare_tsv {
  my ($file1, $file2) = @_;

  my @differences;

  my ($file1handle, $file2handle);
  open($file1handle, "<", $file1) || return "can't open $file1";
  open($file2handle, "<", $file2) || return "can't open $file2";

  my $tsv_parser = Text::CSV_XS->new ({ binary => 1,
					eol => $/,
					sep_char => "\t"
				      });

  while (my $file1row = $tsv_parser->getline($file1handle)) {
    # if it's an empty line
    # read more empty lines until we get something non-empty
    while (defined $file1row && row_is_empty($file1row)) {
      $file1row = $tsv_parser->getline($file1handle)
    }

    # do the same for file2
    my $file2row = $tsv_parser->getline($file2handle);
    while (defined $file2row && row_is_empty($file2row)) {
      $file2row = $tsv_parser->getline($file2handle)
    }

    if (defined $file1row && defined $file2row) {
      # actually compare the contents
      # but we don't care about trailing empty cells, so let's remove them first

      my @array1 = @$file1row;
      my @array2 = @$file2row;

      while (length($array1[$#array1]) == 0) {
	pop @array1;
      }
      while (length($array2[$#array2]) == 0) {
	pop @array2;
      }

      if (@array1 != @array2) {
	# length mismatch
	push @differences, "length mismatch between lines '@array1' and '@array2'\n";
      } else {
	for (my $i=0; $i<@array1; $i++) {
	  if ($array1[$i] ne $array2[$i]) {
	    push @differences, "value mismatch at position $i ('$array1[$i]' ne '$array2[$i]') in lines '@array1' and '@array2'\n";
	  }
	}
      }

    } else {
      if (defined $file1row and !defined $file2row) {
	push @differences, "File 2 finished too soon before '@$file1row'\n";
	return @differences;
      }
      if (defined $file2row and !defined $file1row) {
	push @differences, "File 1 finished too soon before '@$file2row'\n";
	return @differences;
      }
    }

  }


  return @differences;
}


sub row_is_empty {
  my ($arrayref) = @_;
  my @nonempty_values = grep { $_ && length($_) } @$arrayref;
  return @nonempty_values > 0 ? 0 : 1;
}
