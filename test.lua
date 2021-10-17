-- Testing class by pitting two bots against each other

kf = require "knucklefish"
socket = require "socket"
profiler = require "profiler"

-- cutoff: don't do more than this many plies
-- w_careful: true if white should play in careful mode
-- b_careful: true if black should play in careful mode.
-- printboard: true if board should be printed after each ply
-- timing: true if we should print ms/move
-- profile: true if we should run lua profiler
function BOTvBOT(cutoff, w_careful, b_careful, timing, printboard, profile)

   -- use cached moves for white and black
   local wexplored = {}
   local bexplored = {}

   local pos = kf.getInitialState()

   if(profile) then
      profiler.start()
   end

   local white_turn = true
   local peak_time = 0

   local plies = 0
   while(cutoff > plies) do
      plies = plies + 1

      if(timing) then
         starttime = socket.gettime()
      end

      if(white_turn) then
         move = kf.search(pos,wexplored, w_careful)
      else
         move = kf.search(pos,bexplored, b_careful)
      end

      if(timing) then
         time = math.floor(1000 * (socket.gettime() - starttime))
         print("Plies left " .. tostring(plies) .. ": " .. tostring(time) .. "ms")
         if(time > peak) then
            peak = time
         end
      end

      -- If move is nil, we have been checkmated.
      if(move == nil) then
         print("Checkmate.")
         if(white_turn) then
            print("White wins.")
         else
            print("Black wins.")
         end
         return
      else

         print(kf.longalg(move[1]) .. kf.longalg(move[2]))
         -- apply move
         pos = pos:move(move)

         if(white_turn) then
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

         white_turn = not white_turn
      end
   end

   if(profile) then
     profiler.stop()
     profiler.report("profiler.log")
   end

   if(timing) then
      print("peak " .. tostring(peak_time) .. "ms")
   end
end

-- Test function
BOTvBOT(100,true,true,true)
