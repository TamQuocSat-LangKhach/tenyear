local hanying = fk.CreateSkill {
  name = "hanying"
}

Fk:loadTranslationTable{
  ['hanying'] = '寒英',
  ['#SearchFailed'] = '%from 发动 %arg 失败，无法检索到 %arg2',
  ['#hanying-choose'] = '寒英：选择一名手牌数等于你的角色，令其使用%arg',
  [':hanying'] = '准备阶段，你可以展示牌堆顶第一张装备牌，然后令一名手牌数等于你的角色使用之。',
  ['$hanying1'] = '寒梅不争春，空任群芳妒。',
  ['$hanying2'] = '三九寒天，尤有寒英凌霜。',
}

hanying:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(hanying.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = nil
    for _, id in ipairs(room.draw_pile) do
      local c = Fk:getCardById(id)
      if c.type == Card.TypeEquip then
        card = c
        break
      end
    end
    if card == nil then
      room:sendLog{ type = "#SearchFailed", from = player.id, arg = hanying.name, arg2 = "equip" }
      return false
    end
    room:moveCards({
      ids = {card.id},
      toArea = Card.Processing,
      skillName = hanying.name,
      proposer = player.id,
      moveReason = fk.ReasonJustMove,
    })
    local targets = table.map(table.filter(room.alive_players, function (p)
      return p:getHandcardNum() == player:getHandcardNum() and p:canUseTo(card, p)
    end), Util.IdMapper)
    if #targets == 0 then
      room:moveCards{
        ids = {card.id},
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        skillName = hanying.name,
        proposer = player.id,
      }
      return false
    end
    targets = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#hanying-choose:::" .. card:toLogString(),
      skill_name = hanying.name,
      cancelable = false
    })
    --FIXME:暂不考虑赠物（十周年逐鹿天下版）
    room:useCard{
      from = targets[1],
      card = card,
      tos = { targets }
    }
  end
})

return hanying
