#!perl

use strict;
use warnings;
use Chatbot::Eliza;
use Test::More 0.88;
use feature 'say';

my %FINAL = (
	q{Goodbye.  It was nice talking to you.} => 1, 
	q{Goodbye.  I hope you found this session helpful.} => 1, 
	q{I think you should talk to a REAL analyst.  Ciao! } => 1, 
	q{Life is tough.  Hang in there!} => 1,
);

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
	
	my $reply = $bot->interact($args->{text});
	# reply will always have a value
	ok($reply);
	# it could be one of four responses
	is($FINAL{$reply}, 1, "eliza said goodbye - $reply");
};

1;
