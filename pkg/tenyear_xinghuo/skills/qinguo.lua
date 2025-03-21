local qinguo = fk.CreateSkill {
  name = "qinguo",
}

Fk:loadTranslationTable{
  ["qinguo"] = "勤国",
  [":qinguo"] = "当你于回合内使用装备牌结算结束后，你可以视为使用【杀】；当你的装备区里的牌数变化后，若你装备区里的牌数与你的体力值相等，"..
  "你回复1点体力。",

  ["#qinguo-slash"] = "勤国：你可以视为使用一张【杀】",

  ["$qinguo1"] = "为国勤事，体素精勤。",
  ["$qinguo2"] = "忠勤为国，通达治体。",
}

qinguo:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qinguo.name) and
      data.card.type == Card.TypeEquip and player.room.current == player and
      player:canUse(Fk:cloneCard("slash"), {bypass_times = true})
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = qinguo.name,
      prompt = "#qinguo-slash",
      cancelable = true,
      extra_data = {
        bypass_times = true,
        extraUse = true,
      },
      skip = true,
    })
    if use then
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

qinguo:addEffect(fk.AfterCardsMove, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(qinguo.name) and player:isWounded() and #player:getCardIds("e") == player.hp then
      local n = #player:getCardIds("e")
      for _, move in ipairs(data) do
        for _, info in ipairs(move.moveInfo) do
          if move.from == player and info.fromArea == Card.PlayerEquip then
            n = n + 1
          elseif move.to == player and move.toArea == Card.PlayerEquip then
            n = n - 1
          end
        end
      end
      return #player:getCardIds("e") ~= n
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = player,
      num = 1,
      recoverBy = player,
      skillName = qinguo.name,
    }
  end,
})

return qinguo
