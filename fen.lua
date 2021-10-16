-- lichess harness, though will probably work with other engines.
-- accepts FEN as arg to program

kf = require "knucklefish"

local file = io.open("history.txt", "rb")
prevstatesraw = file:read("*a")
file.close()
board_state = arg[1]
to_move = arg[2]
prevstates = {}
for token in string.gmatch(prevstatesraw, "[^|]+") do
   table.insert(prevstates,token)
end


border  =
'         \n' .. --   0 -  9
'         \n ' --  10 - 19

initial = border



-- Prepare board state from FEN notation.
for i = 1, #board_state do
    local c = board_state:sub(i,i)
    local isnum = tonumber(c)

    -- Check if at end of board, and append
    if(c == "/") then
        initial = initial .. "\n "
    -- check if c is one of those slash things
    elseif(isnum ~= nil) then
        for i=1, isnum do
            initial = initial .. "."
        end
    else
        initial = initial .. c
    end
end

initial = initial .. '         \n' .. '           '

local pos = kf.Position.new(initial, 0, {true,true}, {true,true}, 0, 0)

if(to_move == "b") then
  pos = pos:rotate()
end

move = kf.search(pos, prevstates)

if(to_move == "b") then
  print(kf.longalg(119-move[1]) .. kf.longalg(119 - move[2]))
else
  print(kf.longalg(move[1]) .. kf.longalg(move[2]))
end
print("|"..kf.stripWhite(pos:move(move).board))
