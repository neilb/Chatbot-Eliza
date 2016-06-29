#!perl -T

use strict;
use warnings;
use Test::More;
use feature 'say';

use experimental qw[
	signatures
];

BEGIN {
	use_ok( 'Chatbot::Eliza::ScriptParser' ) || print "Bail out!\n";
}

subtest 'unique_words' => sub {
	unique_words({
		words => 'blah foo hello world',
		unique_count => 4
	});
    unique_words({
        words => 'hello hello world order',
        unique_count => 3
    });
    unique_words({
        words => 'one two three three three',
        unique_count => 3
    });
};

done_testing();

sub unique_words ($args) {
	my $parser = Chatbot::Eliza::ScriptParser->new();
	$parser->_unique_words($args->{words});
    is(scalar keys $parser->unique_words->%*, $args->{unique_count}, "expected count $args->{unique_count}"); 
}
