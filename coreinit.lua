--[[  
          Show DOTA MMR changes after match by AveYo v1.1

    SETUP:
    - open Steam Library window -- select Dota 2 -- right-click -- Properties -- Local files -- Browse local files
        that should land you to directory ..\steamapps\common\dota 2 beta\
    - enter directory: game\dota\scripts\vscripts\
    - create directory if it does not exist: core
    - enter directory: core
    - copy paste all this text into a new file named: coreinit.lua 
        enable Show file name extensions in explorer View menu and make sure file is not named coreinit.lua.txt 
    - this file: \steamapps\common\dota 2 beta\game\dota\scripts\vscripts\core\coreinit.lua

    As UI top bar message that auto-hides after 8 seconds:
    <img src="https://i.imgur.com/gk3Ktsw.png">

    As Console message:
    `[VScript] ShowMMR  changed`  
    `09/18/19 16:23:40  Behavior: NORMAL  Core: UNCALIBRATED`  +0  `Support: 6182`  +25

    TIP: to test functionality, open in-game console and enter: cl_class 10,20; hideconsole; disconnect

    v1.1: prevent coordinator down console error   

--]]

local UpdateMMR = function()
  local update = 'hostfile "";developer 1;dota_game_account_client_debug | hostfile;developer 0; dota_mmr | hostfile | hostfile;' 
  SendToServerConsole( update ) -- update current mmr cvar
end
local HideMMR = function(t) SendToServerConsole( 'top_bar_message "" ' .. t )  end
local ShowMMR = function(t)
  UpdateMMR()
  local current = Convars:GetStr( 'hostfile' ):upper() -- get current mmr cvar
  local supp, core = string.match(current, "%a+ : ([%w]+) [%a%_]+ = %a+ : ([%w]+) [%a%_]+ = [%a%_]")
  local bs = string.match(current, "%a+ : [%w]+ [%a%_]+ = %a+ : [%w]+ [%a%_]+ = [%a%_]+: ([%w]+)")
  if bs == nil then bs = "OFFLINE" end 
  local previous = Convars:GetStr( 'cl_class' ) -- get previous mmr cvar
  if previous == (""..core.."."..supp.."") then -- same MMR
    print("ShowMMR  same")
    Msg(GetSystemDate().." "..GetSystemTime().."  Behavior: "..bs.. "  Core: "..core.."  Support:  "..supp.."\n\n")
  elseif previous == "default" then -- initial script setup or cvars reset 
    print("ShowMMR  init")
    Msg(GetSystemDate().." "..GetSystemTime().."  Behavior: "..bs.. "  Core: "..core.."  Support:  "..supp.."\n\n")
    Convars:SetStr( 'cl_class', core.."."..supp ) -- set previous MMR cvar
  else -- changed MMR
    local core1, supp1 = string.match(previous, "(%w+).(%w+)")
    local c, s, c1, s1, c1c, s1s = tonumber(core), tonumber(supp), tonumber(core1), tonumber(supp1), 0, 0
    if c ~= nil and c1 ~= nil then c1c = c - c1 elseif c ~= nil then c1c = c elseif c1 ~= nil then c1c = 0 - c1 end
    if s ~= nil and s1 ~= nil then s1s = s - s1 elseif s ~= nil then s1s = s elseif s1 ~= nil then s1s = 0 - s1 end
    local tcolor, ccolor, scolor = 0, "00FF00FF", "00FF00FF"
    if c1c < 0 then tcolor = 1 ccolor = "FF0000FF" else c1c = "+"..c1c end
    if s1s < 0 then tcolor = 1 scolor = "FF0000FF" else s1s = "+"..s1s end
    local cmd = "grep . "..GetSystemDate().." "..GetSystemTime().."  Behavior: "..bs.."  Core: "..core.."  ;log_color General "
    cmd = cmd.. ccolor.." | grep %;grep . "..c1c.."  ;log_color General 00000000 | grep %;grep . Support: "..supp
    cmd = cmd.. "  ;log_color General "..scolor.." | grep %;grep . "..s1s.."  ;log_color General 00000000 | grep %;echoln;echoln"
    print("ShowMMR  changed")
    SendToServerConsole(cmd) -- pretty print MMR changes
    Convars:SetStr( 'cl_class', core.."."..supp ) -- set previous MMR cvar to the current one
    local VScheduler = EntIndexToHScript(0) -- if there are entities loaded, than vscheduler is available
    if VScheduler then 
      local roses_are_red_violetes_are_blue = 'Core:  '..c1c..("\t"):rep(10)..'BS:  '..bs..("\t"):rep(10)..'Support:  '..s1s
      SendToServerConsole('top_bar_message "'..roses_are_red_violetes_are_blue..'" '..tcolor..';') -- show top bar message 
      VScheduler:SetContextThink( "GabenPlz", function() HideMMR(tcolor) end, 8 ) -- hide after 8 seconds
    end  
  end
end

if SendToServerConsole then -- local server only [ VScripts loads two vm's, one for sv, one for cl ]
  UpdateMMR()
  ListenToGameEvent("player_connect_full", ShowMMR, nil) -- show message after each new map / disconnect
end

--