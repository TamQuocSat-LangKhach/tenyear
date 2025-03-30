local liangjue = fk.CreateSkill {
  name = "liangjue",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["liangjue"] = "粮绝",
  [":liangjue"] = "锁定技，每当一张黑色牌进入或者离开你的判定区或装备区后，你摸两张牌，然后若你的体力值大于1，你失去1点体力。",

  ["$liangjue1"] = "行军者，切不可无粮！",
  ["$liangjue2"] = "粮尽援绝，须另谋出路。",
}

liangjue:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(liangjue.name) then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black and
              (info.fromArea == Card.PlayerJudge or info.fromArea == Card.PlayerEquip) then
              return true
            end
          end
        end
        if move.to == player and (move.toArea == Card.PlayerJudge or move.toArea == Card.PlayerEquip) then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Black then
              return true
            end
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local n = 0
    for _, move in ipairs(data) do
      if move.from == player then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).color == Card.Black and
            (info.fromArea == Card.PlayerJudge or info.fromArea == Card.PlayerEquip) then
            n = n + 1
          end
        end
      end
      if move.to == player and (move.toArea == Card.PlayerJudge or move.toArea == Card.PlayerEquip) then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).color == Card.Black then
            n = n + 1
          end
        end
      end
    end
    for _ = 1, n do
      if not player:hasSkill(liangjue.name) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, liangjue.name)
    if player.hp > 1 then
      player.room:loseHp(player, 1, liangjue.name)
    end
  end,
})

return liangjue
