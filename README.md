Knucklefish.lua
===========

It plays chess.
It runs fast (~10 ms/move).
It makes legal moves.
It doesn't blunder too bad.
and it's in LUA baybee

This is a tiny chess AI that you can embed in your games and things. It can defeat most beginners, but struggles past that.


It's usable in it's current state. Other things in the future though:

- Clean up past state interface
- Consider searching additional plies into the most promising moves. Speed is prioritized, but sometimes it will make moves that look promising on the surface which allows it to be defeated by anyone with basic theory.


Check it out on LiChess: https://lichess.org/@/knucklefish

It does poorly against its fellow bots, which are usually souped up stockfish instances or tend to look past more than two plies. But it tries its best :)
