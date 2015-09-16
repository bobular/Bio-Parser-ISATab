use Test::More tests => 7;
use Data::Dumper;

use Bio::Parser::ISATab;

my $parser = Bio::Parser::ISATab->new(directory=>'./t/Investigation-Study-Comments');
#my $parser = Bio::Parser::ISATab->new(directory=>'./t/BII-S-6');
my $isa = $parser->parse;

ok($isa, "parsed OK");

is($isa->{comments}{'funding source'}, 'NIH', 'investigation comment');
is($isa->{studies}[0]{comments}{soundtrack}, 'heavy metal', 'study comment');

is($isa->{studies}[0]{study_publications}[0]{comments}{URL}, 'http://abc.com', 'study pub 1 URL');
is($isa->{studies}[0]{study_publications}[1]{comments}{URL}, 'https://def.com', 'study pub 2 URL');

is($isa->{studies}[0]{study_publications}[0]{comments}{rating}, '5', 'study pub 1 rating');
is($isa->{studies}[0]{study_publications}[1]{comments}{rating}, '11', 'study pub 2 rating');


#$Data::Dumper::Indent = 1;
#diag(Dumper($isa));

