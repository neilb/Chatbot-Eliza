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
	debug_memory({
		memory => 'goodbye',			
	});
	debug_memory({
		memory => 'bye eliza',			
	});
	debug_memory({
		memory => 'eliza goodbye',			
	});
	debug_memory({
		memory => 'done',			
	});
	debug_memory({
		memory => 'exit',			
	});
	debug_memory({
		memory => 'quit',
	});
};

done_testing();

sub debug_memory {
	my $args = shift;
	
    push $bot->memory->@*, $args->{memory};
    # not testing really
    ok(my $function = $bot->_debug_memory);
    say $function;
};

1;
