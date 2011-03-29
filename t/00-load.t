#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Bio::Parser::ISATab' ) || print "Bail out!
";
}

diag( "Testing Bio::Parser::ISATab $Bio::Parser::ISATab::VERSION, Perl $], $^X" );
