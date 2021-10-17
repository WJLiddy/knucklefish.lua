Knucklefish.lua
===========

It plays chess.
It runs fast (~10 ms/move for the basic version).
It makes legal moves.
It doesn't blunder too bad.
and it's in LUA baybee

This is a tiny chess AI that you can embed in your games and things. It can defeat most beginners, but struggles past that.

It's very easy to use - see attached test.lua

Check it out on LiChess: https://lichess.org/@/knucklefish

It does poorly against its fellow bots, which are usually souped up stockfish instances that tend to look past more than two plies. But it tries its best :)

To help with this, I've added an experimental check for if an opponent move will eventaully lead to checkmate, which seems to work okay. But it can be removed for less processing/less difficulty. Most of the time the bot seems to lose from taking progressively worse trades, which i will accept.
