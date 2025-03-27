local lingfang = fk.CreateSkill {
  name = "lingfang",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["lingfang"] = "凌芳",
  [":lingfang"] = "锁定技，准备阶段，或当其他角色对你使用，或当你对其他角色使用的黑色牌结算后，你获得一枚“绞”标记。",

  ["@dongguiren_jiao"] = "绞",

  ["$lingfang1"] = "曹贼欲加之罪，何患无据可言。",
  ["$lingfang2"] = "花落水自流，何须怨东风。",
}

lingfang:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return player == target and player:hasSkill(lingfang.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@dongguiren_jiao", 1)
  end,
})

lingfang:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(lingfang.name) and data.card.color == Card.Black and #data.tos > 0 then
      if target == player then
        for _, p in ipairs(data.tos) do
          if p ~= player then
            return true
          end
        end
      else
        for _, p in ipairs(data.tos) do
          if p == player then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@dongguiren_jiao", 1)
  end,
})

return lingfang
