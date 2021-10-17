Knucklefish.lua
===========

It plays chess.
It runs fast (~10 ms/move).
It makes legal moves.
It makes bad decisions.
and it's in LUA baybee

This is a tiny chess AI that you can embed in your games and things. It can defeat most beginners, but struggles past that.


It is not quite done, but it is very close. TODO:

- Clean up past state interface
- Disallow moving into check (happens sometimes to avoid 3-fold repetition, we dont want this)
- Consider searching additional plies into the most promising moves. Speed is prioritized, but sometimes it will make moves that look promising on the surface which allows it to be defeated by anyone with basic theory.

Should really have these done by the end of the month..

