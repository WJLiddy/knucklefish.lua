-- knucklefish.lua. a chess AI based on https://github.com/thomasahle/sunfish,
-- but optimized to:
-- use as few instructions as possible
-- return a move that's always legal
-- try to make a move that's at least somewhat reasonable, maybe.

local KF = {}

-- Mate value must be greater than 8*queen + 2*(rook+knight+bishop)
-- King value is set to twice this value such that if the opponent is
-- 8 queens up, but we got the king, we still exceed MATE_VALUE.
KF.MATE_VALUE = 30000

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

__1 = 1 -- 1-index correction
-------------------------------------------------------------------------------
-- Move and evaluation tables
-------------------------------------------------------------------------------
KF.N, KF.E, KF.S, KF.W = -10, 1, 10, -1
KF.directions = {
    P = {KF.N, 2*KF.N, KF.N+KF.W, KF.N+KF.E},
    N = {2*KF.N+KF.E, KF.N+2*KF.E, KF.S+2*KF.E, 2*KF.S+KF.E, 2*KF.S+KF.W, KF.S+2*KF.W, KF.N+2*KF.W, 2*KF.N+KF.W},
    B = {KF.N+KF.E, KF.S+KF.E, KF.S+KF.W, KF.N+KF.W},
    R = {KF.N, KF.E, KF.S, KF.W},
    Q = {KF.N, KF.E, KF.S, KF.W, KF.N+KF.E, KF.S+KF.E, KF.S+KF.W, KF.N+KF.W},
    K = {KF.N, KF.E, KF.S, KF.W, KF.N+KF.E, KF.S+KF.E, KF.S+KF.W, KF.N+KF.W}
}

KF.pst = {
    P = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 198, 198, 198, 198, 198, 198, 198, 198, 0,
        0, 178, 198, 198, 198, 198, 198, 198, 178, 0,
        0, 178, 198, 198, 198, 198, 198, 198, 178, 0,
        0, 178, 198, 208, 218, 218, 208, 198, 178, 0,
        0, 178, 198, 218, 238, 238, 218, 198, 178, 0,
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
-------------------------------------------------------------------------------
-- Chess logic
-------------------------------------------------------------------------------
function KF.isspace(s)
   if s == " " or s == "\n" then
      return true
   else
      return false
   end
end

function KF.isupper(s)
   if s == "." or s == " " or s == "\n" then
      return false
   end
   return s:upper() == s
end

function KF.islower(s)
   if s == "." or s == " " or s == "\n" then
      return false
   end
   return s:lower() == s
end

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

-- since lua strings are immutable, conv to byte array
function KF.swapcase(s)
   tbl = {string.byte(s, 1, -1)}
   vout = {}
   for i = 1, #tbl do
      vout[i] = KF.pieceConv[string.char(tbl[i])]
   end
   return table.concat(vout)
end

KF.Position = {}

function KF.Position.new(board, score, wc, bc, ep, kp) --
   --[[  A state of a chess game
      board -- a 120 char representation of the board
      score -- the board evaluation
      wc -- the castling rights
      bc -- the opponent castling rights
      ep - the en passant square
      kp - the king passant square
   ]] local self = {}
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

function KF.Position:genMoves()
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
               if i == sf.A1 and q == "K" and self.wc[0 + __1] then
                  table.insert(moves, {j, j - 2})
               end
               if i == sf.H1 and q == "K" and self.wc[1 + __1] then
                  table.insert(moves, {j, j + 2})
               end

               -- No friendly captures
               if KF.isupper(q) then
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
                  (i < sf.A1 + KF.N or self.board:sub(i + KF.N + __1, i + KF.N + __1) ~= ".")
                  then
                     break
                  end
               end

               -- Move it
               table.insert(moves, {i, j})
               -- print(i, j)
               -- Stop crawlers from sliding
               if p == "P" or p == "N" or p == "K" then
                  break
               end
               -- No sliding after captures
               if KF.islower(q) then
                  break
               end
            end
         end
      end
   end
   return moves
end

function KF.Position:rotate()
   return self.new(KF.swapcase(self.board:reverse()), -self.score, self.bc, self.wc, 119 - self.ep, 119 - self.kp)
end

function KF.Position:move(move)
   assert(move) -- move is zero-indexed
   local i, j = move[0 + __1], move[1 + __1]
   local p, q = self.board:sub(i + __1, i + __1), self.board:sub(j + __1, j + __1)
   local function put(board, i, p)
      return board:sub(1, i - 1) .. p .. board:sub(i + 1)
   end
   -- Copy variables and reset ep and kp
   local board = self.board
   local wc, bc, ep, kp = self.wc, self.bc, 0, 0
   local score = self.score + self:value(move)
   -- Actual move
   board = put(board, j + __1, board:sub(i + __1, i + __1))
   board = put(board, i + __1, ".")
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
         board = put(board, j < i and KF.A1 + __1 or KF.H1 + __1, ".")
         board = put(board, kp + __1, "R")
      end
   end
   -- Special pawn stuff
   if p == "P" then
      if KF.A8 <= j and j <= KF.H8 then
         board = put(board, j + __1, "Q")
      end
      if j - i == 2 * KF.N then
         ep = i + KF.N
      end
      if ((j - i) == KF.N + KF.W or (j - i) == KF.N + KF.E) and q == "." then
         board = put(board, j + KF.S + __1, ".")
      end
   end
   -- We rotate the returned position, so it's ready for the next player
   return self.new(board, score, wc, bc, ep, kp):rotate()
end

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


-- Original version of sunfish used iterative deepening MTD-bi search...
-- We look at like, all available moves for the ply and pick the best one.
function KF.search(pos)

   local moves = pos:genMoves()

   local bestscore = -KF.MATE_VALUE
   local bestmove = nil

   for i=1,#moves do
      local val = pos:value(moves[i])
      if(val > bestscore) then
         bestscore = val
         bestmove = moves[i]
      end
   end

   return bestmove, bestscore
end

-------------------------------------------------------------------------------
-- User interface
-------------------------------------------------------------------------------

function KF.parse(c)
   if not c then
      return nil
   end
   local p, v = c:sub(1, 1), c:sub(2, 2)
   if not (p and v and tonumber(v)) then
      return nil
   end

   local fil, rank = string.byte(p) - string.byte("a"), tonumber(v) - 1
   return sf.A1 + fil - 10 * rank
end


function KF.render(i)
   local rank, fil = math.floor((i - sf.A1) / 10), (i - sf.A1) % 10
   return string.char(fil + string.byte("a")) .. tostring(-rank + 1)
end

function KF.convmove(i)
   local rank, fil = math.floor((i - sf.A1) / 10), (i - sf.A1) % 10
   return {fil,-rank}
end

KF.strsplit = function(a)
   local out = {}
   while true do
      local pos, _ = a:find("\n")
      if pos then
         out[#out + 1] = a:sub(1, pos - 1)
         a = a:sub(pos + 1)
      else
         out[#out + 1] = a
         break
      end
   end
   return out
end

-- no worko in unity.
function KF.printboard(board)
   local l = KF.strsplit(board, "\n")
   for k, v in ipairs(l) do
      for i = 1, #v do
         io.write(v:sub(i, i))
         io.write("  ")
      end
      io.write("\n")
   end
end

return KF
