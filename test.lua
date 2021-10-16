kf = require "knucklefish"
socket = require "socket"

wexplored = {}
bexplored = {}

function BOTvBOT(timing, profile)
   local pos = kf.Position.new(kf.initial, 0, {true,true}, {true,true}, 0, 0)

   if(profile) then
      local profiler = require("profiler")
      profiler.start()
   end

   i = 10
   AI_TURN = true

   while(i > 0) do
      i = i - 1

      if(timing) then
         
         starttime = socket.gettime()

         if(AI_TURN) then
            move = kf.search(pos,wexplored)
         else
            move = kf.search(pos,bexplored)
         end

         print("Run Time " .. tostring(i) .. ": " .. tostring(math.floor(1000 * (socket.gettime() - starttime))) .. "ms")

      end

      if(move) then
         pmove = {kf.convmove(move[1]),kf.convmove(move[2])}

         if(AI_TURN) then
            pmove = {kf.convmove(119-move[1]),kf.convmove(119-move[2])}
         end

         --print(kf.longalg(move[1]) .. kf.longalg(move[2]))
         --print(pmove[2][1] .. "," .. pmove[2][2])
         
         pos = pos:move(move)

         if(AI_TURN) then
            table.insert(wexplored,kf.stripWhite(pos.board))
            kf.printboard(pos:rotate().board)
         else
            table.insert(bexplored,kf.stripWhite(pos.board))
            kf.printboard(pos.board)
         end

         
         AI_TURN = not AI_TURN
         --if score <= -kf.MATE_VALUE then
         --   print("You won")
         --end
   
         --if score >= kf.MATE_VALUE then
         --   print("You lost")
         --end
      end
   end

   if(profile) then
     profiler.stop()
     profiler.report("profiler.log")
   end
end

-- Test function
BOTvBOT(true,false)
