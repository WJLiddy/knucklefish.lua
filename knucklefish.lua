-- knucklefish.lua. a chess AI based on https://github.com/thomasahle/sunfish,
-- but optimized to:
-- use as few instructions as possible! This is so it can be embedded in games.
-- be somewhat simple to understand - using piece square tables and simple minimax searches.
-- return a move that's always legal
-- try to make a move that's at least somewhat reasonable, maybe, without threefold repeition'ing
-- be okay-ish in the endgame

-- It plays somewhat poorly. It won't blunder pieces, but it can often get into siuations
-- where it loses material quickly. It will probably win against beginners.

local KF = {}

-- Mate value must be greater than 8*queen + 2*(rook+knight+bishop)
-- King value is set to twice this value such that if the opponent is
-- 8 queens up, but we got the king, we still exceed MATE_VALUE.
KF.MATE_VALUE = 30000

-- A little bonus for checking the king, which is usually a good move.
-- Worth more than a pawn.
KF.CHECK_BONUS = 200

-- This is a value that could imply the king is in checkmate.
-- It means that A. the king is in check, and B. has nowhere to move.
-- Checkmate is inevitable unless we have a piece that can un-pin the king.

-- On offense, try to get this state if it costs about half a pawn
KF.KING_ENDANGERED_OFFENSE = 200
-- On defense, up the stakes a little more
KF.KING_ENDANGERED_DEFENSE = 500

-- Our board is represented as a 120 character string. The padding allows for
-- fast detection of moves that don't stay within the board.
KF.A1, KF.H1, KF.A8, KF.H8 = 91, 98, 21, 28

KF.initial = 
    '         \n' .. --   0 -  9
    '         \n' .. --  10 - 19
    ' rnbqkbnr\n' .. --  20 - 29
    ' pppppppp\n' .. --  30 - 39
    ' ........\n' .. --  40 - 49
    ' ........\n' .. --  50 - 59
    ' ........\n' .. --  60 - 69
    ' ........\n' .. --  70 - 79
    ' PPPPPPPP\n' .. --  80 - 89
    ' RNBQKBNR\n' .. --  90 - 99
    '         \n' .. -- 100 -109
    '          '     -- 110 -119

__1 = 1 -- 1-index correction, holdover from sunfish.lua

-- direction for each piece
KF.N, KF.E, KF.S, KF.W = -10, 1, 10, -1
KF.directions = {
    P = {KF.N, 2*KF.N, KF.N+KF.W, KF.N+KF.E},
    N = {2*KF.N+KF.E, KF.N+2*KF.E, KF.S+2*KF.E, 2*KF.S+KF.E, 2*KF.S+KF.W, KF.S+2*KF.W, KF.N+2*KF.W, 2*KF.N+KF.W},
    B = {KF.N+KF.E, KF.S+KF.E, KF.S+KF.W, KF.N+KF.W},
    R = {KF.N, KF.E, KF.S, KF.W},
    Q = {KF.N, KF.E, KF.S, KF.W, KF.N+KF.E, KF.S+KF.E, KF.S+KF.W, KF.N+KF.W},
    K = {KF.N, KF.E, KF.S, KF.W, KF.N+KF.E, KF.S+KF.E, KF.S+KF.W, KF.N+KF.W}
}

-- piece square table
KF.pst = {
    P = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 198, 198, 198, 198, 198, 198, 198, 198, 0,
        0, 178, 198, 198, 198, 198, 198, 198, 178, 0,
        0, 178, 198, 198, 198, 198, 198, 198, 178, 0,
        0, 178, 198, 208, 218, 218, 208, 198, 178, 0,
        0, 178, 198, 218, 298, 298, 218, 198, 178, 0,
        0, 178, 198, 208, 218, 218, 208, 198, 178, 0,
        0, 178, 198, 198, 198, 198, 198, 198, 178, 0,
        0, 198, 198, 198, 198, 198, 198, 198, 198, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    B = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 797, 824, 817, 808, 808, 817, 824, 797, 0,
        0, 814, 841, 834, 825, 825, 834, 841, 814, 0,
        0, 818, 845, 838, 829, 829, 838, 845, 818, 0,
        0, 824, 851, 844, 835, 835, 844, 851, 824, 0,
        0, 827, 854, 847, 838, 838, 847, 854, 827, 0,
        0, 826, 853, 846, 837, 837, 846, 853, 826, 0,
        0, 817, 844, 837, 828, 828, 837, 844, 817, 0,
        0, 792, 819, 812, 803, 803, 812, 819, 792, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    N = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 627, 762, 786, 798, 798, 786, 762, 627, 0,
        0, 763, 798, 822, 834, 834, 822, 798, 763, 0,
        0, 817, 852, 876, 888, 888, 876, 852, 817, 0,
        0, 797, 832, 856, 868, 868, 856, 832, 797, 0,
        0, 799, 834, 858, 870, 870, 858, 834, 799, 0,
        0, 758, 793, 817, 829, 829, 817, 793, 758, 0,
        0, 739, 774, 798, 810, 810, 798, 774, 739, 0,
        0, 683, 718, 742, 754, 754, 742, 718, 683, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    R = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 1258, 1263, 1268, 1272, 1272, 1268, 1263, 1258, 0,
        0, 1258, 1263, 1268, 1272, 1272, 1268, 1263, 1258, 0,
        0, 1258, 1263, 1268, 1272, 1272, 1268, 1263, 1258, 0,
        0, 1258, 1263, 1268, 1272, 1272, 1268, 1263, 1258, 0,
        0, 1258, 1263, 1268, 1272, 1272, 1268, 1263, 1258, 0,
        0, 1258, 1263, 1268, 1272, 1272, 1268, 1263, 1258, 0,
        0, 1258, 1263, 1268, 1272, 1272, 1268, 1263, 1258, 0,
        0, 1258, 1263, 1268, 1272, 1272, 1268, 1263, 1258, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    Q = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 2529, 2529, 2529, 2529, 2529, 2529, 2529, 2529, 0,
        0, 2529, 2529, 2529, 2529, 2529, 2529, 2529, 2529, 0,
        0, 2529, 2529, 2529, 2529, 2529, 2529, 2529, 2529, 0,
        0, 2529, 2529, 2529, 2529, 2529, 2529, 2529, 2529, 0,
        0, 2529, 2529, 2529, 2529, 2529, 2529, 2529, 2529, 0,
        0, 2529, 2529, 2529, 2529, 2529, 2529, 2529, 2529, 0,
        0, 2529, 2529, 2529, 2529, 2529, 2529, 2529, 2529, 0,
        0, 2529, 2529, 2529, 2529, 2529, 2529, 2529, 2529, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    K = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 60098, 60132, 60073, 60025, 60025, 60073, 60132, 60098, 0,
        0, 60119, 60153, 60094, 60046, 60046, 60094, 60153, 60119, 0,
        0, 60146, 60180, 60121, 60073, 60073, 60121, 60180, 60146, 0,
        0, 60173, 60207, 60148, 60100, 60100, 60148, 60207, 60173, 0,
        0, 60196, 60230, 60171, 60123, 60123, 60171, 60230, 60196, 0,
        0, 60224, 60258, 60199, 60151, 60151, 60199, 60258, 60224, 0,
        0, 60287, 60321, 60262, 60214, 60214, 60262, 60321, 60287, 0,
        0, 60298, 60332, 60273, 60225, 60225, 60273, 60332, 60298, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
}

-- endgame piece square tables
KF.king_endgame_pst = 
{0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 60000, 60040, 60080, 60100, 60100, 60080, 60040, 60000, 0,
0, 60040, 60100, 60120, 60140, 60140, 60120, 60100, 60040, 0,
0, 60080, 60120, 60140, 60160, 60160, 60140, 60120, 60080, 0,
0, 60100, 60140, 60160, 60180, 60180, 60160, 60140, 60100, 0,
0, 60100, 60140, 60160, 60180, 60180, 60160, 60140, 60100, 0,
0, 60080, 60120, 60140, 60160, 60160, 60140, 60120, 60080, 0,
0, 60040, 60100, 60120, 60140, 60140, 60120, 60100, 60040, 0,
0, 60000, 60040, 60080, 60100, 60100, 60080, 60040, 60000, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0}

-- try to encourage late game pawns to move up:
-- this undervalues opponent pawns, but that's probably fine..
KF.pawn_endgame_pst = 
{0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 238, 238, 238, 238, 238, 238, 238, 238, 0,
0, 218, 218, 218, 218, 218, 218, 218, 218, 0,
0, 208, 208, 208, 208, 208, 208, 208, 208, 0,
0, 198, 198, 198, 198, 198, 198, 198, 198, 0,
0, 188, 188, 188, 188, 188, 188, 188, 188, 0,
0, 178, 178, 178, 178, 178, 178, 178, 178, 0,
0, 218, 218, 218, 218, 218, 218, 218, 218, 0,
0, 238, 238, 238, 238, 238, 238, 238, 238, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
0, 0, 0, 0, 0, 0, 0, 0, 0, 0}

-- BOARD UTILITY THINGS --
--------------------------

-- check if square is not on the board
function KF.isspace(s)
   if s == " " or s == "\n" then
      return true
   else
      return false
   end
end

-- check if square belongs to the player that is about to move
function KF.isupper(s)
   if s == "." or s == " " or s == "\n" then
      return false
   end
   return s:upper() == s
end

-- check if square belongs to other player
function KF.islower(s)
   if s == "." or s == " " or s == "\n" then
      return false
   end
   return s:lower() == s
end

-- helper for "swapcase"
KF.pieceConv = {
   ["k"] = "K",
   ["r"] = "R",
   ["b"] = "B",
   ["p"] = "P",
   ["n"] = "N",
   ["q"] = "Q",
   ["K"] = "k",
   ["R"] = "r",
   ["B"] = "b",
   ["P"] = "p",
   ["N"] = "n",
   ["Q"] = "q",
   ["."] = ".",
   [" "] = " ",
   ["\n"] = "\n"
}

-- since lua strings are immutable, conv to byte array, this is faster than sub()
-- by swapping character case we change the active player
function KF.swapcase(s)
   tbl = {string.byte(s, 1, -1)}
   vout = {}
   for i = 1, #tbl do
      vout[i] = KF.pieceConv[string.char(tbl[i])]
   end
   return table.concat(vout)
end

-- POSITION CLASS --
--------------------

-- Position class: holds board state, en passant status, castling status
KF.Position = {}

function KF.Position.new(board, score, wc, bc, ep, kp) --
   --[[  A state of a chess game
      board -- a 120 char representation of the board
      score -- the board evaluation
      wc -- the castling rights
      bc -- the opponent castling rights
      ep - the en passant square
      kp - the king passant square
   ]] 
   local self = {}
   self.board = board
   self.score = score
   self.wc = wc
   self.bc = bc
   self.ep = ep
   self.kp = kp
   for k, v in pairs(KF.Position) do
      self[k] = v
   end
   return self
end

-- Generate all possible moves for a player. Note: will move the king into check, which is not a legal move.
-- If "cover" is true, then we allow player to move through the enemy king and project moves onto other pieces.
-- Used for checkmate heuristic in careful mode
function KF.Position:genMoves(cover)
   local moves = {}
   -- For each of our pieces, iterate through each possible 'ray' of moves,
   -- as defined in the 'directions' map. The rays are broken e.g. by
   -- captures or immediately in case of pieces such as knights.
   for i = 1 - __1, #self.board - __1 do
      -- get piece
      local p = self.board:sub(i + __1, i + __1)
      -- run only if piece is ours
      if KF.isupper(p) and KF.directions[p] then
         -- get all directions for piece
         for z=1,#(KF.directions[p]) do
            local d = KF.directions[p][z]
            local limit = (i + d) + (10000) * d -- fake limit
            for j = i + d, limit, d do

               -- new piece position: "q"
               local q = self.board:sub(j + __1, j + __1)

               -- Stay inside the board
               if KF.isspace(self.board:sub(j + __1, j + __1)) then
                  break
               end

               -- Castling
               if i == KF.A1 and q == "K" and self.wc[0 + __1] then
                  table.insert(moves, {j, j - 2})
               end
               if i == KF.H1 and q == "K" and self.wc[1 + __1] then
                  table.insert(moves, {j, j + 2})
               end

               -- No friendly captures
               if KF.isupper(q) then
                  -- used for likely checkmate detection - if king takes the square they die anyway
                  if(cover) then
                     table.insert(moves, {i, j})
                  end
                  break
               end

               -- Special pawn stuff
               if p == "P" then
                  -- no moving left or right if space is empty
                  if (d == KF.N + KF.W or d == KF.N + KF.E) and q == "." and j ~= self.ep and j ~= self.kp then
                     break
                  end

                  -- no moving forward if space is occupied
                  if (d == KF.N or d == 2 * KF.N) and q ~= "." then
                     break
                  end

                  -- no moving forward if first move
                  if d == 2 * KF.N and
                  (i < KF.A1 + KF.N or self.board:sub(i + KF.N + __1, i + KF.N + __1) ~= ".")
                  then
                     break
                  end
               end

               -- Move it
               table.insert(moves, {i, j})

               -- Stop crawlers from sliding
               if p == "P" or p == "N" or p == "K" then
                  break
               end

               -- No sliding after captures
               if KF.islower(q) then
                  -- UNLESS you're in cover mode! in which case we can move through the king (think rooks)
                  if(not cover or q == "k") then
                     break
                  end
               end
            end
         end
      end
   end
   return moves
end

-- helper, move board to other player side.
function KF.Position:rotate()
   return self.new(KF.swapcase(self.board:reverse()), -self.score, self.bc, self.wc, 119 - self.ep, 119 - self.kp)
end

-- helper, put piece on board
function KF.put(board, i, p)
   return board:sub(1, i - 1) .. p .. board:sub(i + 1)
end

-- apply move to position and update score.
function KF.Position:move(move)
   assert(move) -- move is zero-indexed
   local i, j = move[0 + __1], move[1 + __1]
   local p, q = self.board:sub(i + __1, i + __1), self.board:sub(j + __1, j + __1)
   -- Copy variables and reset ep and kp
   local board = self.board
   local wc, bc, ep, kp = self.wc, self.bc, 0, 0
   local score = self.score + self:value(move)
   -- Actual move
   board = kf.put(board, j + __1, board:sub(i + __1, i + __1))
   board = kf.put(board, i + __1, ".")
   -- Castling rights
   if i == KF.A1 then
      wc = {false, wc[0 + __1]}
   end
   if i == KF.H1 then
      wc = {wc[0 + __1], false}
   end
   if j == KF.A8 then
      bc = {bc[0 + __1], false}
   end
   if j == KF.H8 then
      bc = {false, bc[1 + __1]}
   end
   -- Castling
   if p == "K" then
      wc = {false, false}
      if math.abs(j - i) == 2 then
         kp = math.floor((i + j) / 2)
         board = kf.put(board, j < i and KF.A1 + __1 or KF.H1 + __1, ".")
         board = kf.put(board, kp + __1, "R")
      end
   end
   -- Special pawn stuff
   if p == "P" then
      if KF.A8 <= j and j <= KF.H8 then
         board = kf.put(board, j + __1, "Q")
      end
      if j - i == 2 * KF.N then
         ep = i + KF.N
      end
      if ((j - i) == KF.N + KF.W or (j - i) == KF.N + KF.E) and q == "." then
         board = kf.put(board, j + KF.S + __1, ".")
      end
   end
   -- We rotate the returned position, so it's ready for the next player
   return self.new(board, score, wc, bc, ep, kp):rotate()
end

-- get value of move
function KF.Position:value(move)
   local i, j = move[0 + __1], move[1 + __1]
   local p, q = self.board:sub(i + __1, i + __1), self.board:sub(j + __1, j + __1)

   -- Actual move
   local score = KF.pst[p][j + __1] - KF.pst[p][i + __1]

   -- Capture
   if KF.islower(q) then
      score = score + KF.pst[q:upper()][j + __1]
   end
   -- Castling check detection
   if math.abs(j - self.kp) < 2 then
      score = score + KF.pst["K"][j + __1]
   end

   -- Castling
   if p == "K" and math.abs(i - j) == 2 then
      score = score + KF.pst["R"][math.floor((i + j) / 2) + __1]
      score = score - KF.pst["R"][j < i and KF.A1 + __1 or KF.H1 + __1]
   end

   -- Special pawn stuff
   if p == "P" then
      if KF.A8 <= j and j <= KF.H8 then
         score = score + KF.pst["Q"][j + __1] - KF.pst["P"][j + __1]
      end
      if j == self.ep then
         score = score + KF.pst["P"][j + KF.S + __1]
      end
   end
   return score
end

-- AI FUNCTIONS --
------------------

-- return true if endgame, meaning we should use new PST. Defined as less than seven major or minor pieces.
function KF.endgame(board)
   local pieces = "QNRBqrnb"
   local count = 0
   for i=1,#pieces do
      local _,r = board:gsub(string.sub(pieces,i,i),"")
      count = count + r
   end
   return (count <= 6)
end

-- Quick check for if a major or minor piece puts king in check
-- This function expensive, so we ignore pawn moves which aren't likely to do anything.
-- This function is important for not stalemating the endgame and using careful mode
function KF.probablyInCheck(move,board)
   -- Piece is at i, but went to "n"
   local i, n = move[0 + __1], move[1 + __1]
   local p = board:sub(i + __1, i + __1)

   -- dont deal with pawns lol
   if(p == "P") then
      return false
   end

-- Piece "P" has gone to "n".
-- Check if this put the king in check.
-- See "Position.genMoves"
   for z=1,#(KF.directions[p]) do
      local d = KF.directions[p][z]
      local limit = (n + d) + (10000) * d -- fake limit
      for j = n + d, limit, d do
         -- new piece position: "q"
         local q = board:sub(j + __1, j + __1)

         -- Ran into a King? - they're probably in check
         if q == "k" then
            return true
         end

         -- Hit something that's not an empty space.
         if (q ~= ".") then
            break
         end

         -- Stop crawlers from sliding
         if p == "P" or p == "N" or p == "K" then
            break
         end
      end
   end
   return false
end

-- Check for if a king has no safe place to move
-- This function is VERY expensive.
-- This likely means they are in checkmate. The only way they can avoid this
-- is if one of their pieces rescues them. Speed over accuracy.
function KF.kingEndangered(pos,move)
   -- first, apply the move.
   local i, j = move[0 + __1], move[1 + __1]
   local p, q = pos.board:sub(i + __1, i + __1), pos.board:sub(j + __1, j + __1)
   
   --save old board state
   local oldboard = pos.board

   pos.board = kf.put(pos.board, j + __1, pos.board:sub(i + __1, i + __1))
   pos.board = kf.put(pos.board, i + __1, ".")
   -- move's applied.

   -- Here are the king's options.
   local kbase = string.find(pos.board,"k")
   local kdirs = {}
   kdirs[kbase] = true
   for n=1,#kf.directions.K do
      local loc = kbase + kf.directions.K[n]
      --print(string.sub(pos.board,loc,loc))
      if(string.sub(pos.board,loc,loc) == "." or kf.isupper(string.sub(pos.board,loc,loc))) then
         -- king can move or take here
         kdirs[loc] = true
      end
   end

   -- see if we can move to any of king's positions.
   local l = pos:genMoves(true)

   for n=1,#l do
      kdirs[l[n][2] + 1] = false
   end

   -- fixold board.
   pos.board = oldboard

   -- king has an escape
   for k,v in pairs(kdirs) do
      if(v == true) then
         return false
      end
   end

   -- king has no escape.
   return true
end

-- custom comparator to compare value of two moves.
function KF.compare(a, b)
   return a[2] < b[2]
end

-- classic minimax min
function KF.min(pos, move, careful)
   local npos = pos:move(move)
   local nmoves = npos:genMoves()
   local best = nil
   local bestscore = - kf.MATE_VALUE * 2
   -- pick the best move we can, remember that reverse() was called.
   for j=1,#nmoves do
      local val = (npos.score + npos:value(nmoves[j]))

      -- In careful mode, the min is more likely to pick moves that check or threaten the king.
      -- So we check for that to avoid moving there.
      -- However, toggling this mode is somewhat expensive, so it's optional.
      if(careful) then
         if(kf.probablyInCheck(nmoves[j], npos.board)) then
            val = val + kf.CHECK_BONUS
            if(kf.kingEndangered(npos,nmoves[j])) then
               val = val + kf.KING_ENDANGERED_DEFENSE
            end
         end
      end
     
      if(val > bestscore) then
         bestscore = val
      end
   end
   return bestscore
end

-- classic minimax max
function KF.max(pos,careful)
   local moves = pos:genMoves()
   local results = {}
   for i=1,#moves do 
      -- Make the move and see my position after the opponent makes their best move.
      local val = KF.min(pos, moves[i], careful)

      -- See if we can check or endanger the king
      if(KF.probablyInCheck(moves[i],pos.board)) then
         val = val - KF.CHECK_BONUS
         if(kf.kingEndangered(pos,moves[i])) then
            val = val - kf.KING_ENDANGERED_OFFENSE
         end
      end
      table.insert(results,{moves[i],val})
   end

   -- sort by lowest first (min returns in terms of opponent material)
   table.sort(results,KF.compare)
   return results
end

-- CACHING FUNCTIONS --
-----------------------

-- strip opponent pieces from the board, to be cached later.
-- this is important for avoiding threefold repetition, bot would constantly stalemate otherwise.
function KF.stripOppPieces(board)
   alts = "KQRPNB"
   local nboard = board
   for i=1,#alts do
     nboard = string.gsub(nboard,string.sub(alts,i,i),".")
   end
   return nboard
 end
 
-- return the move is original., that is to say not in cached.
function KF.not_repeated(board_stripped, states)
   for j=1, #states do
      if(states[j] == board_stripped) then
         return false
      end
   end
   return true
end

-- "PUBLIC" FUNCTIONS --
------------------------

-- Return starting board state
function KF.getInitialState()
   return kf.Position.new(kf.initial, 0, {true,true}, {true,true}, 0, 0)
end

-- THE SEARCH FUNCTION
-- pos: the game position (obtained from getInitialState()... initally)
-- states: list of states we have seen already, can be nil if we don't care about 3fold rep
-- careful: pass true for careful mode, which means we won't fall into checkmate as easily. Optional but you _should_ turn it on.
function KF.search(pos, states, careful)
   if(states == nil) then
      states = {}
   end

   if(kf.endgame(pos.board)) then
      KF.pst.K = KF.king_endgame_pst
      KF.pst.P = KF.pawn_endgame_pst
   end

   local moves = KF.max(pos, careful)

   for i=1,#moves do
      local next_move = kf.stripOppPieces(pos:move(moves[i][1]).board)
      -- Do not choose a move that puts us in mate
      if(moves[i][2] < kf.MATE_VALUE) then
         -- Do not choose a move that we've moved to before
         if(kf.not_repeated(next_move, states)) then
            return moves[i][1]
         end
      end
    end

   -- At this point, there were no new moves that did not also put us into checkmate.
   -- So, repeated moves are tolerated here only.
   for i=1,#moves do
      -- play the best move that isn't mate.
      if(moves[i][2] < kf.MATE_VALUE) then
         return moves[i][1]
      end
    end

   return nil
end

-- PRINT FUNCTIONS --
----------------------

-- change board position to long algebraic form. For UCI standard.
function KF.longalg(i)
   local rank, fil = math.floor((i - KF.A1) / 10), (i - KF.A1) % 10
   return string.char(fil + string.byte("a")) .. tostring(-rank + 1)
end

return KF
