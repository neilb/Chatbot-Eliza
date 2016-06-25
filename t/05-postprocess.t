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
		text => 'hello world',			
	    expected => 'hello world',			
    });
	goodbye_eliza({
		text => 'hello recolect',			
	    expected => 'hello recollect',			
    });
	goodbye_eliza({
		text => 'eliza goodbye',			
	    expected => 'eliza goodbye',			
    });
	goodbye_eliza({
		text => 'done certainle',			
	    expected => 'done certainly',			
    });
	goodbye_eliza({
		text => 'maybr',			
	    expected => 'maybe',			
    });
	goodbye_eliza({
		text => 'machynes',
        expected => 'machines',			
	});
};

done_testing();

sub goodbye_eliza {
	my $args = shift;
	
	my $reply = $bot->postprocess($args->{text});
	# reply will always have a value
	ok($reply);
	is($reply, $args->{expected}, "we went through postprocess - $reply");
};

1;
