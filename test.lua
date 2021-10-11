kf = require "knucklefish"


local pos = kf.Position.new(kf.initial, 0, {true,true}, {true,true}, 0, 0)

--local profiler = require("profiler")
--profiler.start()

i = 0

while(true) do
   move, score = kf.search(pos)

   if(move) then
      pmove = {kf.convmove(move[1]),kf.convmove(move[2])}

      if(AI_TURN) then
         pmove = {kf.convmove(119-move[1]),kf.convmove(119-move[2])}
      end


      AI_TURN = not AI_TURN
      pos = pos:move(move)
      kf.printboard(pos.board)

      if score <= -kf.MATE_VALUE then
         print("You won")
      end
 
      if score >= kf.MATE_VALUE then
         print("You lost")
      end
   end
end


kf.printboard(pos:rotate().board)
-- Code block and/or called functions to profile --

--profiler.stop()
--profiler.report("profiler.log")
