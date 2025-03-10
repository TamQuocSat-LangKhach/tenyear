local ty__shanjia = fk.CreateSkill {
  name = "ty__shanjia"
}

Fk:loadTranslationTable{
  ['ty__shanjia'] = '缮甲',
  ['#ty__shanjia-discard'] = '缮甲：你需弃置%arg张牌',
  ['#ty__shanjia-use'] = '缮甲：你可以视为使用【杀】',
  ['@ty__shanjia'] = '缮甲',
  [':ty__shanjia'] = '出牌阶段开始时，你可以摸三张牌，然后弃置三张牌（你每不因使用而失去过一张装备牌，便少弃置一张），若你本次没有弃置过：基本牌，你此阶段使用【杀】次数上限+1；锦囊牌，你此阶段使用牌无距离限制；都满足，你可以视为使用【杀】。',
  ['$ty__shanjia1'] = '百锤锻甲，披之可陷靡阵、断神兵、破坚城！',
  ['$ty__shanjia2'] = '千炼成兵，邀天下群雄引颈，且试我剑利否！'
}

ty__shanjia:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(ty__shanjia) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:drawCards(3, ty__shanjia.name)
    local cards = {}
    if player:getMark(ty__shanjia.name) < 3 then
      local x = 3 - player:getMark(ty__shanjia.name)
      cards = room:askToDiscard(player, {
        min_num = x,
        max_num = x,
        include_equip = true,
        skill_name = ty__shanjia.name,
        cancelable = false,
        pattern = ".",
        prompt = "#ty__shanjia-discard:::"..x
      })
    end
    local flag1, flag2 = false, false
    if not table.find(cards, function(id) return Fk:getCardById(id).type == Card.TypeBasic end) then
      flag1 = true
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-turn", 1)
    end
    if not table.find(cards, function(id) return Fk:getCardById(id).type == Card.TypeTrick end) then
      flag2 = true
      room:addPlayerMark(player, MarkEnum.BypassDistancesLimit.."-turn", 1)
    end
    if flag1 and flag2 then
      U.askForUseVirtualCard(room, player, "slash", nil, ty__shanjia.name, "#ty__shanjia-use", true, true, false, true)
    end
  end,
})

ty__shanjia:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player)
    return player:getMark(ty__shanjia.name) < 3
  end,
  on_refresh = function(self, event, target, player)
    local n = 0
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason ~= fk.ReasonUse then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).type == Card.TypeEquip then
            n = n + 1
          end
        end
      end
    end
    if n > 0 then
      player.room:addPlayerMark(player, ty__shanjia.name, math.min(n, 3 - player:getMark(ty__shanjia.name)))
      if player:hasSkill(ty__shanjia, true) then
        player.room:setPlayerMark(player, "@ty__shanjia", player:getMark(ty__shanjia.name))
      end
    end
  end,
})

return ty__shanjia
