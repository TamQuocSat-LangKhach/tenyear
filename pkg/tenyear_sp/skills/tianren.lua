local tianren = fk.CreateSkill {
  name = "tianren",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["tianren"] = "天任",
  [":tianren"] = "锁定技，当一张基本牌或普通锦囊牌不因使用而置入弃牌堆后，你获得1个“天任”标记，然后若“天任”标记数不小于X，你移去X个“天任”标记，"..
  "加1点体力上限并摸两张牌（X为你的体力上限）。",

  ["@tianren"] = "天任",

  ["$tianren1"] = "举石补苍天，舍我更复其谁？",
  ["$tianren2"] = "天地同协力，何愁汉道不昌？"
}

tianren:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(tianren.name) then
      for _, move in ipairs(data) do
        if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if card.type == Card.TypeBasic or card:isCommonTrick() then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = 0
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and move.moveReason ~= fk.ReasonUse then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if card.type == Card.TypeBasic or card:isCommonTrick() then
            x = x + 1
          end
        end
      end
    end
    room:addPlayerMark(player, "@tianren", x)
    while player:getMark("@tianren") >= player.maxHp do
      room:removePlayerMark(player, "@tianren", player.maxHp)
      room:changeMaxHp(player, 1)
      if player.dead then return false end
      player:drawCards(2, tianren.name)
      if player.dead then return false end
    end
  end,
})

tianren:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@tianren", 0)
end)

return tianren
