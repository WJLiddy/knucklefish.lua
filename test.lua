kf = require "knucklefish"


function BOTvBOT()
   local pos = kf.Position.new(kf.initial, 0, {true,true}, {true,true}, 0, 0)

   --local profiler = require("profiler")
   --profiler.start()

   i = 0
   AI_TURN = true

   while(true) do
      i = i + 1
      move, score = kf.search(pos)

      if(move) then
         pmove = {kf.convmove(move[1]),kf.convmove(move[2])}

         if(AI_TURN) then
            pmove = {kf.convmove(119-move[1]),kf.convmove(119-move[2])}
         end

         print(kf.longalg(move[1]) .. kf.longalg(move[2]))
         print(pmove[2][1] .. "," .. pmove[2][2])
         
         AI_TURN = not AI_TURN
         pos = pos:move(move)

         if(AI_TURN) then
            kf.printboard(pos:rotate().board)
         else
            kf.printboard(pos.board)

         end

         if score <= -kf.MATE_VALUE then
            print("You won")
         end
   
         if score >= kf.MATE_VALUE then
            print("You lost")
         end
      end
   end
   --profiler.stop()
   --profiler.report("profiler.log")
end

-- Test function
BOTvBOT()