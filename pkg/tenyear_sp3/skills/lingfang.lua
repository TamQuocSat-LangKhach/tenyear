local lingfang = fk.CreateSkill {
  name = "lingfang"
}

Fk:loadTranslationTable{
  ['lingfang'] = '凌芳',
  ['@dongguiren_jiao'] = '绞',
  [':lingfang'] = '锁定技，准备阶段或当其他角色对你使用或你对其他角色使用的黑色牌结算后，你获得一枚“绞”标记。',
  ['$lingfang1'] = '曹贼欲加之罪，何患无据可言。',
  ['$lingfang2'] = '花落水自流，何须怨东风。',
}

lingfang:addEffect(fk.EventPhaseStart, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(lingfang.name) and player == target and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@dongguiren_jiao", 1)
  end,
})

lingfang:addEffect(fk.CardUseFinished, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(lingfang.name) then return false end
    if data.card.color == Card.Black and data.tos then
      local realTargets = TargetGroup:getRealTargets(data.tos)
      if target == player then
        for _, id in ipairs(realTargets) do
          if id ~= player.id then
            return true
          end
        end
      else
        for _, id in ipairs(realTargets) do
          if id == player.id then
            return true
          end
        end
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@dongguiren_jiao", 1)
  end,
})

return lingfang
