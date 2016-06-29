use FindBin::libs;
use Chatbot::Eliza;
my $bot = Chatbot::Eliza->new();
$bot->command_interface;

1;
