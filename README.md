Knucklefish.lua
===========

It plays chess.
It runs fast (under 10 ms/move for the basic version, around 30ms with careful :tm: mode enabled).
It makes legal moves.
It doesn't blunder too bad.
and it's in LUA baybee.

This is a tiny chess AI that you can embed in your games and things. It can defeat most beginners, but struggles past that.

It uses a two-ply minimax algorithm with a simple but fairly fast board state generator, with different piece square tables for the endgame. About seven hundred lines, including comments.

It's very easy to use:



- see attached test.lua



The careful:tm: mode adds a little more processing time but uses a checkmate heuristic to avoid making blunders like this:




Check it out on LiChess: https://lichess.org/@/knucklefish

It does poorly against its fellow bots, which are usually souped up stockfish instances that tend to look past more than two plies. But it tries its best :)

To help with this, I've added an experimental check for if an opponent move will eventaully lead to checkmate, which seems to work okay. But it can be removed for less processing/less difficulty. Most of the time the bot seems to lose from taking progressively worse trades, which i will accept.

![image](https://user-images.githubusercontent.com/8826899/137644069-6bd950da-f6cb-4e71-bd16-cf4e1cc782ac.png)
