use Test::More tests => 24;
use Data::Dumper;

use Bio::Parser::ISATab;

my $parser = Bio::Parser::ISATab->new(directory=>'./t/BII-I-1');
isa_ok($parser, 'Bio::Parser::ISATab');

my $isa = $parser->parse;
ok(defined($isa), 'parse returns something');

is($isa->{investigation_identifier}, 'BII-I-1', 'investigation_identifier');
is($isa->{ontologies}[0]{term_source_name}, 'BTO', 'term_source_name');
is($isa->{ontologies}[5]{term_source_name}, 'PATO', 'term_source_name');

is($isa->{investigation_publications}[0]{investigation_publication_doi}, 'doi:10.1186/jbiol54', 'investigation_publication_doi');
unlike($isa->{investigation_publications}[0]{investigation_publication_author_list}, qr/"/, 'there should be no quotes in author list');

is($isa->{studies}[0]{study_identifier}, 'BII-S-1', 'first study_identifier');
is($isa->{studies}[1]{study_identifier}, 'BII-S-2', 'second study_identifier');

is($isa->{studies}[0]{study_file_name}, 's_BII-S-1.txt', 'first study_file_name');
is($isa->{studies}[1]{study_file_name}, 's_BII-S-2.txt', 'second study_file_name');

is($isa->{studies}[1]{study_factors}[0]{study_factor_name}, 'compound', 'study_factor_name compound');
is($isa->{studies}[1]{study_factors}[2]{study_factor_name}, 'dose', 'study_factor_name dose');

is($isa->{studies}[1]{study_protocols}[0]{study_protocol_name}, 'EukGE-WS4', 'study_protocol_name');
like($isa->{studies}[1]{study_protocols}[0]{study_protocol_description}, qr/Invitrogen/, 'study_protocol_description');

# check semicolon-delimited multiple values
is($isa->{studies}[0]{study_protocols}[6]{study_protocol_parameters}[0]{study_protocol_parameter_name}, 'sample volume', 'study_protocol_parameter_name (semicolon delimited)');
is($isa->{studies}[0]{study_protocols}[6]{study_protocol_parameters}[1]{study_protocol_parameter_name}, 'standard volume', 'study_protocol_parameter_name (semicolon delimited)');

# slightly special treatment for initials - just a simple array of strings (not a hash)
is($isa->{investigation_contacts}[0]{investigation_person_mid_initials}[0], 'G', 'investigation contact initials');
is($isa->{studies}[0]{study_contacts}[0]{study_person_mid_initials}[0], 'G', 'study contact initials');



is($isa->{studies}[0]{study_assays}[0]{study_assay_file_name}, 'a_metabolome.txt');
is($isa->{studies}[0]{study_assays}[1]{study_assay_technology_platform}, 'iTRAQ');

#
# test lookups
#

is($isa->{ontology_lookup}{'PATO'}{term_source_description}, 'Phenotypic qualities (properties)');
is($isa->{studies}[0]{study_protocol_lookup}{'biotin labeling'}{study_protocol_type}, 'labeling');
is($isa->{studies}[0]{study_protocol_lookup}{'metabolite extraction'}{study_protocol_parameter_lookup}{'sample volume'}{study_protocol_parameter_name}, 'sample volume');

$Data::Dumper::Indent = 1;
#diag(Dumper($isa));
