-- lichess harness, though will probably work with other engines with minor tweaks.
-- You probably have no use for this, except that you may want to poach convertFEN() for your project.

kf = require "knucklefish"

-- Prepare board state from FEN notation.
function convertFEN(fen)
  local initial  =
  '         \n' .. --   0 -  9
  '         \n '   --  10 - 19

  for i = 1, #fen do
      local c = fen:sub(i,i)
      local isnum = tonumber(c)

      -- Check if at end of board, and append
      if(c == "/") then
          initial = initial .. "\n "
      -- check if c is a number
      elseif(isnum ~= nil) then
          for i=1, isnum do
              initial = initial .. "."
          end
      else
          initial = initial .. c
      end
  end
  initial = initial .. '         \n' .. '           '
  return initial
end

-- read from "history.txt" which contains previous positions.
function readHistory()
  local file = io.open("history.txt", "rb")
  if file==nil then
    -- Could not read history, no problem.
    -- Silent failure here not ideal but w/e
    return {}
  end
  local prevstatesraw = file:read("*a")
  file.close()
  local ret = {}
  for token in string.gmatch(prevstatesraw, "[^|]+") do
    table.insert(ret,token)
  end
  return ret
end

-- Passed from cmd line
board_state_fen = arg[1]
to_move = arg[2]
prevstates = {}

-- THIS IS A BUG: use FEN to provide castle and en-passant state.
-- Works 99% of the time on lichess for now, though.
local pos = kf.Position.new(initial, 0, {true,true}, {true,true}, 0, 0)

pos.board = convertFEN(board_state_fen)
prevstates = readHistory()

if(to_move == "b") then
  pos = pos:rotate()
end

move = kf.search(pos, prevstates, true)

-- Output: the move to be caputured by subprocess()
-- Use a pipe as a seperator because we need to tell python to stuff the boardstate in history.txt.

if(to_move == "b") then
  print(kf.longalg(119-move[1]) .. kf.longalg(119 - move[2]))
else
  print(kf.longalg(move[1]) .. kf.longalg(move[2]))
end

print("|"..kf.stripOppPieces(pos:move(move).board))
