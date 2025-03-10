local jingyi = fk.CreateSkill {
  name = "jingyi"
}

Fk:loadTranslationTable{
  ['jingyi'] = '精益',
  [':jingyi'] = '锁定技，每个装备栏每回合限一次，当牌进入你的装备区后，你摸X张牌（X为你装备区里的牌数），然后弃置两张牌。',
  ['$jingyi1'] = '精益求精，工如道，途无穷。',
  ['$jingyi2'] = '木可伐，石可破，技不可失。',
}

jingyi:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(jingyi.name) or player.room:getCurrent() == nil then return false end
    local mark = player:getTableMark("jingyi-turn")
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Card.PlayerEquip then
        for _, info in ipairs(move.moveInfo) do
          if not table.contains(mark, Fk:getCardById(info.cardId).sub_type) then
            return true
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local mark = player:getTableMark("jingyi-turn")
    for _, move in ipairs(data) do
      if move.to == player.id and move.toArea == Card.PlayerEquip then
        for _, info in ipairs(move.moveInfo) do
          table.insertIfNeed(mark, Fk:getCardById(info.cardId).sub_type)
        end
      end
    end
    player.room:setPlayerMark(player, "jingyi-turn", mark)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local x = #player:getCardIds(Player.Equip)
    if x > 0 then
      player:drawCards(x, jingyi.name)
      if player.dead then return false end
    end
    player.room:askToDiscard(player, {
      min_num = 2,
      max_num = 2,
      include_equip = true,
      skill_name = jingyi.name,
      cancelable = false,
    })
  end,
})

jingyi:addEffect("on_lose", {
  on_lose = function (skill, player)
    player.room:setPlayerMark(player, "jingyi-turn", {})
  end
})

return jingyi
