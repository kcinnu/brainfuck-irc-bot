# an IRC bot written in brainfuck

## how to run it
`zig run bf.zig -lc -- nickname #channel ircnetwork.example.com`
or `zig build-exe bf.zig -lc` and `./bf nickname etc...`
you can omit the IRC network if you want to become the IRC network

## how to use it
the bot only has one command, and its `!add`.
use it like this: `!add 9+10`
the command *DOES NOT* handle whitespace between numbers, and if theres a missing `+` sign it wont respond to pings or messages until it sees another `+`

## description of the files
`bf.zig`: brainfuck interpreter + supporting code that puts nick & channel into the tape, and wires the brainfuck i/o into a socket
`irc.zig`: a quick prototype to see if i understood the IRC protocol correctly
`ircbot.bf`: the actual source code for the irc bot (i wrote most of it manually, except for the massive chains of +/-s needed for dealing with ascii, which i made with a short javascript script)
