#!perl

use strict;
use warnings;
use Chatbot::Eliza;
use Test::More 0.88;
use feature 'say';

# doesn't store memory so it's actually pretty useless
my $bot = new Chatbot::Eliza {
	name => "Eliza",
	memory_on => 0,
	prompts_on => 1,
};

subtest 'say goodbye in multiple ways' => sub {
	goodbye_eliza({
		text => 'goodbye',			
	});
	goodbye_eliza({
		text => 'bye eliza',			
	});
	goodbye_eliza({
		text => 'eliza goodbye',			
	});
	goodbye_eliza({
		text => 'done',			
	});
	goodbye_eliza({
		text => 'exit',			
	});
	goodbye_eliza({
		text => 'quit',			
	});
};

done_testing();

sub goodbye_eliza {
	my $args = shift;
	
	my $reply = $bot->_testquit($args->{text});
	# reply will always have a value
	# it could be one of four responses
	is($reply, 1, "eliza said goodbye - $reply");
};

1;
