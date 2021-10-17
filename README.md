Knucklefish.lua
===========

It plays chess.
It runs fast (around 15 ms/move for the basic version, a few more with careful:tm: mode enabled).
It makes legal moves.
It doesn't blunder too bad.
and it's in LUA baybee.

This is a tiny chess AI that you can embed in your games and things. It can defeat most beginners, but struggles past that.

It uses a two-ply minimax algorithm with a simple but fairly fast board state generator, with different piece square tables for the endgame. About seven hundred lines, including comments.

It's very easy to use:

```
kf = require "knucklefish"
local pos = kf.getInitialState()
move = kf.search(pos)
print(kf.longalg(move[1]) .. kf.longalg(move[2]))
```

- see attached test.lua



The careful:tm: mode adds a little more processing time but uses a checkmate heuristic to avoid making blunders like this:




Check it out on LiChess: https://lichess.org/@/knucklefish

It does poorly against its fellow bots, which are usually souped up stockfish instances that tend to look past more than two plies. But it tries its best :)

To help with this, I've added a check for if an opponent move will eventually lead to checkmate, which seems to work okay at the cost of extra time. But it can be removed for less processing/less difficulty. Most of the time the bot seems to lose from taking progressively worse trades, which i will accept.
