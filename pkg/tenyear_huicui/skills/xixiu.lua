local xixiu = fk.CreateSkill {
  name = "xixiu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xixiu"] = "皙秀",
  [":xixiu"] = "锁定技，当你成为其他角色使用牌的目标后，若你装备区内有与此牌花色相同的牌，你摸一张牌；其他角色不能弃置你装备区内的最后一张牌。",

  ["$xixiu1"] = "君子如玉，德形皓白。",
  ["$xixiu2"] = "木秀于身，芬芳自如。",
}

xixiu:addEffect(fk.TargetConfirmed, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xixiu.name) and data.from ~= player.id and
      table.find(player:getCardIds("e"), function(id)
        return Fk:getCardById(id):compareSuitWith(data.card)
      end)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, xixiu.name)
  end,
})

xixiu:addEffect(fk.BeforeCardsMove, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xixiu.name) and #player:getCardIds("e") == 1 then
      for _, move in ipairs(data) do
        if move.from == player and move.moveReason == fk.ReasonDiscard and move.proposer ~= player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:cancelMove(data, player:getCardIds("e"))
  end,
})

return xixiu
