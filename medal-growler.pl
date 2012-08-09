#!perl

use strict;
use warnings;

use AnyEvent::Twitter::Stream;
use Config::Pit;
use Growl::Any;
use Encode;
use utf8;

binmode STDOUT, ":utf8";

my $growl = Growl::Any->new(appname => "medal-growler", events => ["tweet"]);

my $config = pit_get("twitter.com", require => {
    ConsumerKey => "consumer key",
    ConsumerSecret => "consumer token",
    AccessToken => "access token",
    AccessTokenSecret => "access token secret"
});

my $done = AnyEvent->condvar;
my $listener = AnyEvent::Twitter::Stream->new(
    consumer_key => $config->{ConsumerKey},
    consumer_secret => $config->{ConsumerSecret},
    token => $config->{AccessToken},
    token_secret => $config->{AccessTokenSecret},
    method => "filter",
    track => "#olympic,#london2012",
    on_tweet => sub {
        my $tweet = shift;
        my $screen_name = $tweet->{user}->{screen_name};
        my $text = $tweet->{text};
        my $icon = $tweet->{user}->{profile_image_url};
        if( $text =~ /(金|銀|銅).+(おめでとう)/ ) {
            $growl->notify(
                "tweet", $screen_name, $text, $icon,
            );
        }
        print "$screen_name: $text\n";
    },
    on_error => sub {
        my $error = shift;
        warn "ERROR: $error";
        $done->send;
    },
    on_eof => sub {
        $done->send;
    },
);

$done->recv;
