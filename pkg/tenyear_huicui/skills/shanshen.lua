local shanshen = fk.CreateSkill {
  name = "shanshen",
}

Fk:loadTranslationTable{
  ["shanshen"] = "善身",
  [":shanshen"] = "当一名角色死亡时，你可以令〖隅泣〗中的一个数字+2（单项不能超过5）。若你没有对其造成过伤害，你回复1点体力。",

  ["#yuqi-upgrade"] = "%arg：选择令“隅泣”中的一个数字+%arg2",

  ["$shanshen1"] = "好善为德，坚守本心。",
  ["$shanshen2"] = "洁身自爱，独善其身。",
}

local function AddYuqi(player, skillName, num)
  local room = player.room
  local choices = {}
  local all_choices = {}
  local yuqi_initial = {0, 3, 1, 1}
  for i = 1, 4, 1 do
    table.insert(all_choices, "yuqi" .. i)
    if player:getMark("yuqi" .. i) + yuqi_initial[i] < 5 then
      table.insert(choices, "yuqi" .. i)
    end
  end
  if #choices > 0 then
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = skillName,
      prompt = "#yuqi-upgrade:::"..skillName..":"..num,
      all_choices = all_choices,
    })
    room:setPlayerMark(player, choice, math.min(5 - yuqi_initial[table.indexOf(all_choices, choice)], player:getMark(choice) + num))
  end
end

shanshen:addEffect(fk.Death, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(shanshen.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:hasSkill("yuqi", true) then
      AddYuqi(player, shanshen.name, 2)
    end
    if player:isWounded() and
      #player.room.logic:getActualDamageEvents(1, function(e)
        local damage = e.data
        if damage.from == player and damage.to == target then
          return true
        end
      end, Player.HistoryGame) == 0 then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = shanshen.name,
      }
    end
  end,
})

return shanshen
