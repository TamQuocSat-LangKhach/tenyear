local xianjing = fk.CreateSkill {
  name = "xianjing",
}

Fk:loadTranslationTable{
  ["xianjing"] = "娴静",
  [":xianjing"] = "准备阶段，你可以令〖隅泣〗中的一个数字+1（单项不能超过5）。若你满体力值，则再令〖隅泣〗中的一个数字+1。",

  ["$xianjing1"] = "文静娴丽，举止柔美。",
  ["$xianjing2"] = "娴静淡雅，温婉穆穆。",
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

xianjing:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(xianjing.name) and player.phase == Player.Start and
      player:hasSkill("yuqi", true) then
      local yuqi_initial = {0, 3, 1, 1}
      for i = 1, 4 do
        if player:getMark("yuqi"..i) + yuqi_initial[i] < 5 then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    AddYuqi(player, xianjing.name, 1)
    if not player:isWounded() then
      AddYuqi(player, xianjing.name, 1)
    end
  end,
})

return xianjing
