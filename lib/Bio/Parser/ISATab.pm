package Bio::Parser::ISATab;

use Mouse;
use warnings;
use strict;
use Carp;
use Text::CSV_XS;
use Tie::Hash::Indexed;
use Data::Dumper;

require 5.10.1;

=head1 NAME

Bio::Parser::ISATab - Parse ISA-Tab to a hash-based data structure.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

Parser for the ISA-Tab format (multiple files in one directory).
See http://isatab.sourceforge.net/specifications.html

    use Bio::Parser::ISATab;

    my $parser = Bio::Parser::ISATab->new(directory=>'expt1-isa-tab-v1');
    my $isa = $parser->parse;
    print "Title: ".$isa->{investigation_title}."\n";

Investigation and Study-level comments are now allowed. See
https://groups.google.com/forum/#!topic/isaforum/x5Yzj395cHQ
for examples.

=head1 LIMITATIONS

Issues not fully adressed:

=over

=item * File encodings

=item * Mac/DOS newlines

=item * Standardising some common inconsitencies (e.g. Factor Value and FactorValue)

=item * 'treatment order' qualifiers as described on p27 of ISA-TAB v1.0 RC1 specs.

=item * multiple protocols per processing step not tested

=item * empty cells (for nodes, protocols or attributes) might not be handled well

=item * no checks yet made to see if protocol REFs, factor values, etc are valid (it's not hard to do)

=item * non-pooling behaviour of files and 'Data Transformation Name' may not conform to standard

=item * factor values are attached to last-seen biological material (source, sample, extract, labeled extract)

=back

=head1 Constructor attributes

=head2 directory

Required.

Location of the ISA-Tab directory, containing the i_xxxx.txt,
s_yyyy.txt and a_zzzz.txt files.

=cut

#
#note: this is all done with Moose magic.
#      these are the arguments to the 'new' constructor
#      which is all taken care of for us.
#

has 'directory' => (
		    is => 'ro',
		    required => 1,
		   );


=head2 investigation_file

NOT YET IMPLEMENTED

Specifies which investigation file to use if there are more than one matching
<directory>/i_*.txt

=cut


=head2 tsv_parser 

Text::CSV_XS object for internal use only.

=cut

has tsv_parser => (
		   is => 'ro',
		   lazy => 1,
		   builder => '_build_tsv_parser',
);

sub _build_tsv_parser {
  return Text::CSV_XS->new ({ binary => 1,
			      eol => $/,
			      sep_char => "\t"
			    });
}


#
# lookup from all caps section heading
#
my %section_headings = (
			'ONTOLOGY SOURCE REFERENCE' => 'ontologies',
			'INVESTIGATION' => 'investigation',
			'INVESTIGATION PUBLICATIONS' => 'investigation_publications',
			'INVESTIGATION CONTACTS' => 'investigation_contacts',
			'STUDY' => 'study',
			'STUDY DESIGN DESCRIPTORS' => 'study_designs',
			'STUDY PUBLICATIONS' => 'study_publications',
			'STUDY FACTORS' => 'study_factors',
			'STUDY ASSAYS' => 'study_assays',
			'STUDY PROTOCOLS' => 'study_protocols',
			'STUDY CONTACTS' => 'study_contacts',
);

#
# key is ISA-Tab column 0 heading, value is the hash key for the array of mutiple 'objects'
#
my %semicolon_delimited = ( 'Investigation Person Mid Initials' => 'investigation_person_mid_initials',

			    'Investigation Person Roles' => 'investigation_person_roles',
			    'Investigation Person Roles Term Accession Number' => 'investigation_person_roles',
			    'Investigation Person Roles Term Source Ref' => 'investigation_person_roles',
			    'Investigation Person Roles Term Source REF' => 'investigation_person_roles',

			    #typo/inconsistency in ISA-Tab 1.0RC1 specs
			    'Study Person Mid Initials' => 'study_person_mid_initials',
			    'Study Person Mid Initial' => 'study_person_mid_initials',

			    'Study Protocol Parameters Name' => 'study_protocol_parameters',
			    'Study Protocol Parameters Name Term Accession Number' => 'study_protocol_parameters',
			    'Study Protocol Parameters Name Term Source Ref' => 'study_protocol_parameters',
			    'Study Protocol Parameters Name Term Source REF' => 'study_protocol_parameters',

			    'Study Protocol Components Name' => 'study_protocol_components',
			    'Study Protocol Components Type' => 'study_protocol_components',
			    'Study Protocol Components Type Term Accession Number' => 'study_protocol_components',
			    'Study Protocol Components Type Term Source Ref' => 'study_protocol_components',
			    'Study Protocol Components Type Term Source REF' => 'study_protocol_components',

			    'Study Person Roles' => 'study_person_roles',
			    'Study Person Roles Term Accession Number' => 'study_person_roles',
			    'Study Person Roles Term Source Ref' => 'study_person_roles',
			    'Study Person Roles Term Source REF' => 'study_person_roles',
);

=head1 SUBROUTINES/METHODS

=head2 parse

Returns a hashref for the investigation/studies/assays.

More details on the structure to follow, or see the test code in t/01-invest.t

# ONTOLOGY SOURCE REFERENCE
$isa->{ontologies}[0]{term_source_name} = '...';
$isa->{ontologies}[0]{term_source_file} = '...';
$isa->{ontologies}[0]{term_source_version} = '...';
$isa->{ontologies}[0]{term_source_description} = '...';
# lookup version of arrays with compulsory names/ids
$isa->{ontology_lookup}{NAME}{term_source_name} = '...'; # where NAME is the Term Source Name, e.g. PATO
$isa->{ontology_lookup}{NAME}{term_source_file} = '...'; # etc

=cut

sub parse {
  my $self = shift;
  my $isa = ordered_hashref();
  $isa->{studies} = [];

  croak "Can't find ISA-Tab directory '".$self->directory."'" unless (-d $self->directory);

  # look for a unique investigation file i_*.txt

  my @i_files = glob $self->directory."/i_*.txt";
  croak("No investigation files found") if (@i_files == 0);
  croak "Multiple investigation files found.  Bio::Parser::ISATab does not yet handle this yet." if (@i_files > 1);
  my $i_file = shift @i_files;

  # open the i_file WITHOUT CONSIDERING ENCODINGS - MUST FIX
  open(my $i_fh, $i_file) or croak "couldn't open $i_file";

  my $current_section;
  my $table = []; # used to store the rows/cols from the last section
  my $study_index = -1; # increment each time we enter a STUDY section

  # read each line with the tsv parser
  while (my $row = $self->tsv_parser->getline($i_fh)) {
    if (!defined $row->[0] || $row->[0] eq '' || $row->[0] =~ /^#/) {
      # this is a comment or an empty line
    } elsif (defined $section_headings{$row->[0]}) {
      # we just moved into a new section
      # process previous table (warning: end of loop code duplication)
      if (defined $current_section && @$table) {
	process_table($isa, $study_index, $current_section, $table);
      }
      $table = [];
      $current_section = $section_headings{$row->[0]};

      # special treatment of new STUDY section (vertically repeatable)
      if ($current_section eq 'study') {
	$isa->{studies}[++$study_index] = ordered_hashref();
      }
    } elsif ($current_section =~ /s$/) {
      # we're in a multi-column section, so add to $table
      push @{$table}, $row;
    } else {
      my $isa_ref = $isa;
      if ($current_section eq 'study') {
	# single column study section
	$isa_ref = $isa->{studies}[$study_index];
      }
      if ($row->[0] =~ /^Comment\s*\[(.+)\]\s*$/) {
	$isa_ref->{comments} ||= ordered_hashref();
	$isa_ref->{comments}{$1} = defined $row->[1] ? $row->[1] : '';
      } else {
	$isa_ref->{lcu($row->[0])} = defined $row->[1] ? $row->[1] : '';
      }
    }
  }

  # annoying end of loop code duplication...
  if (defined $current_section && @$table) {
    process_table($isa, $study_index, $current_section, $table);
  }

  close($i_fh);

  #
  # create the convenience lookups for ontologies and protocols
  #
  create_lookup($isa, 'ontologies', 'ontology_lookup', 'term_source_name');
  foreach my $study (@{$isa->{studies}}) {
    create_lookup($study, 'study_protocols', 'study_protocol_lookup', 'study_protocol_name');
    foreach my $protocol_name (keys %{$study->{study_protocol_lookup}}) {
      my $protocol = $study->{study_protocol_lookup}{$protocol_name};
      create_lookup($protocol, 'study_protocol_parameters', 'study_protocol_parameter_lookup', 'study_protocol_parameter_name');
      create_lookup($protocol, 'study_protocol_components', 'study_protocol_component_lookup', 'study_protocol_component_name');
    }
    create_lookup($study, 'study_factors', 'study_factor_lookup', 'study_factor_name');
  }

  #
  # load the study and assay tables
  #

  foreach my $study (@{$isa->{studies}}) {
    $study->{sources} = $self->parse_study_or_assay($study->{study_file_name}, $isa)->{sources};
    foreach my $assay (@{$study->{study_assays}}) {
      my $assaydata = $self->parse_study_or_assay($assay->{study_assay_file_name}, $isa);
      $assay->{sources} = $assaydata->{sources} if ($assaydata->{sources});
      $assay->{samples} = $assaydata->{samples} if ($assaydata->{samples});
    }
    # create a lookup with keys like 'field collection', 'phenotype assay'
    create_lookup($study, 'study_assays', 'study_assay_lookup', 'study_assay_measurement_type');
  }

  return $isa;
}

=head1 NON-PUBLIC METHODS AND FUNCTIONS

=head2 parse_study_or_assay

args: $self, $filename, $isa, $custom_column_types

$isa is OPTIONAL (for checking that protocols and ontologies have been defined)

$custom_column_types is a hashref like this

  {
    'Phenotype Name' => 'reusable node',
    Type => 'attribute',
    Observable => 'attribute',
  }

which adds another (pooling) node type
('non-reusable node' (non-pooling) is another allowed type)
and two extra attribute-like columns (like "Material Type" in standard ISA-Tab)

=cut

#
# these are columns which can trigger a pooling event (convergence in the DAG)
#
my %reusable_node_types = ('Source Name' => 'sources',
			   'Sample Name' => 'samples',
			   'Extract Name' => 'extracts',
			   'Labeled Extract Name' => 'labeled_extracts',
			   'MS Assay Name' => 'ms_assays',
			   'Assay Name' => 'assays',
			   'Hybridization Assay Name' => 'hybridization_assays',
			   'Gel Electrophoresis Assay Name' => 'gel_electrophoresis_assays',
			   'NMR Assay Name' => 'nmr_assays',
			   'Scan Name' => 'scans',
			   'Normalization Name' => 'normalizations', # maybe make non-reusable?
);

#
# and these are columns which don't.
#
# The point here is that an Array Design REF might be used in all assays but the columns to the
# right of this column would be different so you can't "re-use" the data you read in for
# the previous row with the same Array Design REF.
#
# note, values (used as keys in the $isa data structure) have been pluralised except for the array design
#

my %non_reusable_node_types = ('Data Transformation Name' => 'data_transformations',
			       'Raw Data File' => 'raw_data_files',
			       'Image File' => 'image_files',
			       'Array Design File' => 'array_design_file',
			       'Array Design REF' => 'array_design_ref',
			       'Array Design Ref' => 'array_design_ref',
##?			       'Array Design File REF' => 'array_design_file_ref',
			       'Derived Data File' => 'derived_data_files',
			       'Array Data File' => 'array_data_files',
			       'Derived Array Data File' => 'derived_array_data_files',
			       'Array Data Matrix File' => 'array_data_matrix_files',
			       'Derived Array Data Matrix File' => 'derived_array_data_matrix_files',
			       'Spot Picking File' => 'spot_picking_files',
			       'Raw Spectral Data File' => 'raw_spectral_data_files',
			       'Derived Spectral Data File' => 'derived_spectral_data_files',
			       'Peptide Assignment File' => 'peptide_assignment_files',
			       'Protein Assignment File' => 'protein_assignment_files',
			       'Post Translational Modification Assignment File' => 'post_translational_modification_assignment_files',
			       'Free Induction Decay Data File' => 'free_induction_decay_data_files',
			       'Acquisition Parameter Data File' => 'acquisition_parameter_data_files',
			       'Metabolite Assignment File' => 'metabolite_assignment_files',
);


sub parse_study_or_assay {
  my ($self, $study_file, $isa, $custom_column_types) = @_;

  my $result = ordered_hashref();

  my $headers;
  my $n;
  my $node_type_cache = ordered_hashref(); # node_type -> name -> { ... } # allows pooling

  $study_file = $self->directory()."/".$study_file;

  open(my $s_fh, $study_file) or croak "couldn't open $study_file";
  while (my $row = $self->tsv_parser->getline($s_fh)) {
    #carp join("\t", @$row); #debugging
    if ($row->[0] =~ /^#/) {
      # it's a comment, do nothing
    } elsif (defined $headers) {
      # we're in the data, process it

      my $node_type; # e.g. sources, samples
      my $current_node = $result; # pointer to where we are in the hash DAG
      my $last_biological_material; # used to attach factor_values to

      my $current_attribute; # pointer to latest location in hash which might need qualifying
      # (e.g. Term Accession Number, Term Source REF)

      my $current_protocol; # pointer to the latest protocol which might need qualifying

      for (my $i=0; $i<$n; $i++) {
	my $header = $headers->[$i];
	my $value = defined $row->[$i] ? $row->[$i] : '';
	if ($reusable_node_types{$header} ||
	    (defined $custom_column_types->{$header} && $custom_column_types->{$header} eq 'reusable node')) {
	  # need step down one level into the DAG
	  $node_type = $reusable_node_types{$header} // pluralise_custom_column($header);

	  if (length($value)) {
	    # see if we already have a node by this name ($value) at this level ($node_type)
	    $node_type_cache->{$node_type}{$value} ||= ordered_hashref();
	    # assigning the new (or reused) node as a child of the 'current node'
	    $current_node->{$node_type} ||= ordered_hashref();
	    $current_node->{$node_type}{$value} = $node_type_cache->{$node_type}{$value};
	    # now set the current node to be this child
	    $current_node = $current_node->{$node_type}{$value};
	    $last_biological_material = $current_node if ($node_type =~ /^(source|sample|extract|labeled)/); # hack alert!
	  }
	  undef $current_attribute;
	  undef $current_protocol;
	} elsif ($non_reusable_node_types{$header} ||
		 (defined $custom_column_types->{$header} &&
		  $custom_column_types->{$header} eq 'non-reusable node')) {
	  # need step down one level into the DAG
	  $node_type = $non_reusable_node_types{$header} // pluralise_custom_column($header);

	  if (length($value)) {
	    # assigning the new node as a child of the 'current node'
	    $current_node->{$node_type}{$value} = ordered_hashref();
	    # now set the current node to be this child
	    $current_node = $current_node->{$node_type}{$value};
	  }
	  undef $current_attribute;
	  undef $current_protocol;
	} elsif ($header =~ /^(Characteristics|Factor Value)\s*\[(.+)\]\s*$/) {
	  my $key = lcu($1);
	  my $type = $2;
	  $key =~ s/s?$/s/; # make plural lowercase underscored, e.g. factor_values

	  # factor values need special treatment (don't attach them to files and other non-reusable nodes)
	  my $node_to_annotate = $key eq 'factor_values' ? $last_biological_material : $current_node;
	  $node_to_annotate->{$key} ||= ordered_hashref();
	  check_and_set(\$node_to_annotate->{$key}{$type}{value}, $value) if (length($value));
	  $current_attribute = $node_to_annotate->{$key}{$type};
	} elsif ($header =~ /^Comment\s*\[(.+)\]\s*$/) {
	  my $type = $1;
	  $current_node->{comments} ||= ordered_hashref();
	  check_and_set(\$current_node->{comments}{$type}, $value) if (length($value));
	} elsif ($header eq 'Material Type' || $header eq 'Label' ||
		 (defined $custom_column_types->{$header} && $custom_column_types->{$header} eq 'attribute')) {
	  check_and_set(\$current_node->{lcu($header)}{value}, $value) if (length($value));
	  $current_attribute = $current_node->{lcu($header)};
	} elsif ($header eq 'Unit' && $current_attribute) {
	  check_and_set(\$current_attribute->{unit}{value}, $value) if (length($value));
	  $current_attribute = $current_attribute->{unit};
	} elsif ($header =~ /^Protocol REF$/i && length($value)) {
	  $current_node->{protocols} ||= ordered_hashref();
	  $current_node->{protocols}{$value} ||= ordered_hashref();
	  $current_protocol = $current_node->{protocols}{$value};
	} elsif ($header =~ /^(Parameter Value)\s*\[(.+)\]\s*$/ && $current_protocol) {
	  $current_protocol->{parameter_values} ||= ordered_hashref();
	  check_and_set(\$current_protocol->{parameter_values}{$2}{value}, $value) if (length($value));
	  $current_attribute = $current_protocol->{parameter_values}{$2};
	} elsif ($header =~ /^(Performer|Date)$/ && $current_protocol) {
	  check_and_set(\$current_protocol->{lc($1)}, $value) if (length($value));
	} elsif ($header =~ /^Term (Source REF|Accession Number)$/i && $current_attribute && length($value)) {
	  check_and_set(\$current_attribute->{lcu($header)}, $value);
	} elsif ($header eq 'Description' && length($value)) {
	  # simply stored as $node->{description} = "text ...";
	  # NOT $node->{description}{value} = ...
	  check_and_set(\$current_node->{lcu($header)}, $value);
	} elsif (length($value)) {
	  # this warning is really just for debugging - we don't want to let any non-empty cells through the net
	  # carp "probable valueless annotation of $headers->[$i-1] qualified by $header => $value (column $i of $study_file)";
	} else {
	  # it was just an empty cell
	}

      }
    } else {
      # store the headers
      $headers = $row;
      $n = @{$headers};
    }

  }
  close($s_fh);
  return $result;
}


=head2 check_and_set

Assigns a value into the result hash, but cannot overwrite an existing entry
unless it is identical.

=cut

sub check_and_set {
  my ($hashlocref, $value) = @_;
  if (defined $$hashlocref && $$hashlocref ne $value) {
    carp "Trying to overwrite ".Dumper($$hashlocref)."$$hashlocref with $value\n";
  } else {
    $$hashlocref = $value;
  }
}

=head2 process_table

Walks horizontally across a table, storing data into $isa

=cut

sub process_table {
  my ($isa, $study_index, $section_name, $rows) = @_;

  # find the number of columns in the table
  # by looking for the row with the right-most non-empty contents
  my $num_cols = 0;
  foreach my $row (@$rows) {
    for (my $i=@$row-1; $i>0; $i--) {
      if (defined $row->[$i] && length($row->[$i]) > 0) {
	$num_cols = $i if ($i > $num_cols);
	last;
      }
    }
  }

  # if this section of the ISA-Tab is not empty
  # walk across table and store data
  if ($num_cols > 0) {

    # where do we put the data, under $isa or under $isa->{studies}[INDEX]?
    my $isa_ptr = $section_name =~ /^study/ ? $isa->{studies}[$study_index] : $isa;

    for (my $i=0; $i<$num_cols; $i++) {
      my %num_values_seen; # plural_key => num_values => 1;  for semicolon delimited only
      foreach my $row (@$rows) {

	if (defined (my $plural_key = $semicolon_delimited{$row->[0]})) {
	  # this row may need semicolon splitting
	  my @values = split /\s*;\s*/, ($row->[$i+1] || ''), -1;
	  $num_values_seen{$plural_key}{scalar @values} = 1 if (@values > 0);
	  if ($plural_key =~ /initials$/) {
	    $isa_ptr->{$section_name}[$i]{$plural_key} = \@values;
	  } else {
	    for (my $j=0; $j<@values; $j++) {
	      $isa_ptr->{$section_name}[$i]{$plural_key}[$j]{plural_subkey($row->[0], $plural_key)} = defined $values[$j] ? $values[$j] : '';
	    }
	  }
	} elsif ($row->[0] =~ /^Comment\s*\[(.+)\]\s*$/) {
	  $isa_ptr->{$section_name}[$i]{comments} ||= ordered_hashref();
	  $isa_ptr->{$section_name}[$i]{comments}{$1} = defined $row->[$i+1] ? $row->[$i+1] : '';
	} else {
	  $isa_ptr->{$section_name}[$i]{lcu($row->[0])} = defined $row->[$i+1] ? $row->[$i+1] : '';
	}
      }

      # check if there were any problems with the semicolon delimiting
      foreach my $plural_key (keys %num_values_seen) {
	my $study_insert = $section_name =~ /^study/ ? "{studies}[$study_index]" : '';
	croak "Parsing error!\nFor column $i in \$isa->$study_insert\{$section_name\}\{$plural_key\}, semicolon delimiting is not consistent."
	  if (keys %{$num_values_seen{$plural_key}} > 1);
      }
    }
  }

}

=head2 lcu

return lower case and s/\s/_/g string

=cut

sub lcu {
  my $in = shift;
  my $out = lc($in);
  $out =~ s/\s/_/g;
  return $out;
}

=head2 plural_subkey

return the key for the final level in the hash for semicolon-delimited values (contact roles, protocol params)

=cut

sub plural_subkey {
  my ($in, $plural_key) = @_;
  # first do the normal lower case thing
  my $out = lcu($in);

  my $singular_key = $plural_key;
  $singular_key =~ s/s$//;

  # then remove the leading $plural_key if it's followed by _something
  $out =~ s/^$plural_key/$singular_key/;
  return $out;
#  } else {
#    # return singular version of $plural_key
#    $out = $plural_key;
#    $out =~ s/s$//;
#    return $out;
#  }
}

=head2 pluralise_custom_column

Naively lower-case pluralises the column name, removing "name" as appropriate.

e.g.
  "Widget Name" -> "widgets"
  "Special Instrument Name" -> "special_instruments"
  "Sheep Name" -> "sheeps"

=cut

sub pluralise_custom_column {
  my ($input) = @_;
  $input = lcu($input);
  $input =~ s/_name$//;
  return $input.'s';
}



=head2 create_lookup

args: $hashref, $arraykey, $lookupkey, $itemkey

example

  create_lookup($study, 'study_protocols', 'study_protocol_lookup', 'study_protocol_name');
  # or from outside this package
  Bio::Parser::ISATab::create_lookup($study, 'study_contacts', 'study_contact_lookup', 'study_person_email');

This will go through the array of study_protocols, and create "shortcuts" to the protocols
using the study_protocol_name as the lookup key

  $study->{study_protocol_lookup}{growth} = { ... };
  $study->{study_protocol_lookup}{extraction} = { ... };

=cut


sub create_lookup {
  my ($hashref, $arraykey, $lookupkey, $itemkey) = @_;
  foreach my $item (@{$hashref->{$arraykey}}) {
    croak "could not create $lookupkey from $arraykey due to missing $itemkey\n" unless ($item->{$itemkey});
    $hashref->{$lookupkey}{$item->{$itemkey}} = $item;
  }
}


=head2 ordered_hashref

Wrapper for Tie::Hash::Indexed - returns a hashref which has already been tied to Tie::Hash::Indexed

no args.

usage: $foo->{bar} = ordered_hashref();  $foo->{bar}{hello} = 123;

=cut

sub ordered_hashref {
  my $ref = {};
  tie %{$ref}, 'Tie::Hash::Indexed';
  return $ref;
}

=head1 AUTHOR

Bob MacCallum, C<< <r.maccallum at imperial.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-parser-isatab at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Parser-ISATab>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::Parser::ISATab


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-Parser-ISATab>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-Parser-ISATab>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bio-Parser-ISATab>

=item * Search CPAN

L<http://search.cpan.org/dist/Bio-Parser-ISATab/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Bob MacCallum.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

__PACKAGE__->meta->make_immutable;

1; # End of Bio::Parser::ISATab
