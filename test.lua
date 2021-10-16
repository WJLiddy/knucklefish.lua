kf = require "knucklefish"
socket = require "socket"
profiler = require "profiler"

wexplored = {}
bexplored = {}

-- aiming for soft limit of 20 ms.

function BOTvBOT(printboard, timing, profile, i)
   local pos = kf.Position.new(kf.initial, 0, {true,true}, {true,true}, 0, 0)

   if(profile) then
      profiler.start()
   end

   AI_TURN = true
   peak = 0

   while(i > 0) do
      i = i - 1

      if(timing) then
         starttime = socket.gettime()
      end

         if(AI_TURN) then
            move = kf.search(pos,wexplored)
         else
            move = kf.search(pos,bexplored)
         end

         if(timing) then
         time = math.floor(1000 * (socket.gettime() - starttime))
         print("Run Time " .. tostring(i) .. ": " .. tostring(time) .. "ms")
         if(time > peak) then
            peak = time
         end
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
            if(printboard) then
               kf.printboard(pos:rotate().board)
            end
         else
            table.insert(bexplored,kf.stripWhite(pos.board))
            if(printboard) then
               kf.printboard(pos.board)
            end
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

   if(timing) then
      print("peak " .. tostring(peak) .. "ms")
   end
end

-- Test function
BOTvBOT(false, false, true, 30)
