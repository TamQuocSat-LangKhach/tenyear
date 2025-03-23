local qiangzhiz = fk.CreateSkill {
  name = "qiangzhiz"
}

Fk:loadTranslationTable{
  ['qiangzhiz'] = '强峙',
  ['needhand'] = '对方手牌',
  ['needequip'] = '对方装备',
  ['wordhand'] = '我的手牌',
  ['wordequip'] = '我的装备',
  [':qiangzhiz'] = '出牌阶段限一次，你可以弃置你和一名其他角色共计三张牌。若有角色因此弃置三张牌，其对另一名角色造成1点伤害。',
  ['$qiangzhiz1'] = '吾民在后，岂惧尔等魍魉。',
  ['$qiangzhiz2'] = '凶兵来袭，当长戈相迎。',
}

qiangzhiz:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(qiangzhiz.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player.id and
      #Fk:currentRoom():getPlayerById(to_select):getCardIds{Player.Hand, Player.Equip} + #player:getCardIds{Player.Hand, Player.Equip} > 2
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card_data = {}
    if #target:getCardIds(Player.Hand) > 0 then
      local handcards = {}
      for _ = 1, #target:getCardIds(Player.Hand), 1 do
        table.insert(handcards, -1)
      end
      table.insert(card_data, { "needhand", handcards })
    end
    if #target:getCardIds(Player.Equip) > 0 then
      table.insert(card_data, { "needequip", target:getCardIds(Player.Equip) })
    end
    if #player:getCardIds(Player.Hand) > 0 then
      table.insert(card_data, { "wordhand", player:getCardIds(Player.Hand) })
    end
    if #player:getCardIds(Player.Equip) > 0 then
      table.insert(card_data, { "wordequip", player:getCardIds(Player.Equip) })
    end
    local cards = room:askToChooseCards(player, {
      min = 3,
      max = 3,
      flag = { card_data = card_data },
      skill_name = qiangzhiz.name,
    })
    local cards1 = table.filter(cards, function(id) return table.contains(player:getCardIds{Player.Hand, Player.Equip}, id) end)
    local cards2 = table.filter(cards, function(id) return table.contains(target:getCardIds{Player.Hand, Player.Equip}, id) end)
    local moveInfos = {}
    if #cards1 > 0 then
      table.insert(moveInfos, {
        from = player.id,
        ids = cards1,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = effect.from,
        skillName = qiangzhiz.name,
      })
    end
    if #cards2 > 0 then
      table.insert(moveInfos, {
        from = target.id,
        ids = cards2,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonDiscard,
        proposer = effect.from,
        skillName = qiangzhiz.name,
      })
    end
    room:moveCards(table.unpack(moveInfos))
    if not player.dead and not target.dead then
      if #cards1 == 3 then
        room:damage{
          from = player,
          to = target,
          damage = 1,
          skillName = qiangzhiz.name,
        }
      elseif #cards2 == 3 then
        room:damage{
          from = target,
          to = player,
          damage = 1,
          skillName = qiangzhiz.name,
        }
      end
    end
  end,
})

return qiangzhiz
