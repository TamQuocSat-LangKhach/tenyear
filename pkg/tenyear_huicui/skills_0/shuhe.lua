local shuhe = fk.CreateSkill {
  name = "shuhe"
}

Fk:loadTranslationTable{
  ['shuhe'] = '数合',
  ['@ty__liehou'] = '列侯',
  ['#shuhe-choose'] = '数合：选择一名其他角色，将%arg交给其',
  [':shuhe'] = '出牌阶段限一次，你可以展示一张手牌，并获得场上与展示牌相同点数的牌，然后〖列侯〗的额外摸牌数+1（至多为5）。如果你没有因此获得牌，你需将展示牌交给一名其他角色',
  ['$shuhe1'] = '齐心共举，万事俱成。',
  ['$shuhe2'] = '手足协力，天下可往。',
}

shuhe:addEffect('active', {
  anim_type = "control",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(shuhe.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Card.PlayerEquip
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    player:showCards(effect.cards)
    local card = Fk:getCardById(effect.cards[1])
    local cards = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      for _, id in ipairs(p:getCardIds{Player.Equip, Player.Judge}) do
        if Fk:getCardById(id).number == card.number then
          table.insert(cards, id)
        end
      end
    end
    if #cards > 0 then
      room:moveCardTo(cards, Player.Hand, player, fk.ReasonPrey, shuhe.name, "", true, player.id)
      if player.dead then return false end
    end
    if player:getMark("@ty__liehou") < 5 then
      room:addPlayerMark(player, "@ty__liehou", 1)
    end
    if #cards == 0 then
      local targets = table.map(room:getOtherPlayers(player, true), Util.IdMapper)
      if #targets == 0 then return false end
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#shuhe-choose:::"..card:toLogString(),
        skill_name = shuhe.name,
        cancelable = false,
      })
      room:obtainCard(to[1], card, true, fk.ReasonGive)
    end
  end,
})

return shuhe
