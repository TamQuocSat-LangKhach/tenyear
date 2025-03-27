local xianjing = fk.CreateSkill {
  name = "xianjing"
}

Fk:loadTranslationTable{
  ['xianjing'] = '娴静',
  ['yuqi'] = '隅泣',
  [':xianjing'] = '准备阶段，你可令〖隅泣〗中的一个数字+1（单项不能超过5）。若你满体力值，则再令〖隅泣〗中的一个数字+1。',
  ['$xianjing1'] = '文静娴丽，举止柔美。',
  ['$xianjing2'] = '娴静淡雅，温婉穆穆。',
}

xianjing:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(xianjing.name) and player.phase == Player.Start then
      local yuqi_initial = {0, 3, 1, 1}
      for i = 1, 4 do
        if player:getMark("yuqi" .. tostring(i)) + yuqi_initial[i] < 5 then
          return true
        end
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    AddYuqi(player, xianjing.name, 1)
    if not player:isWounded() then
      AddYuqi(player, xianjing.name, 1)
    end
  end,
})

return xianjing
