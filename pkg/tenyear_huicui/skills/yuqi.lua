local yuqi = fk.CreateSkill {
  name = "yuqi",
  dynamic_desc = function(player)
    return
      "yuqi_inner:" ..
      player:getMark("yuqi1") .. ":" ..
      (player:getMark("yuqi2") + 3) .. ":" ..
      (player:getMark("yuqi3") + 1) .. ":" ..
      (player:getMark("yuqi4") + 1)
  end,
}

Fk:loadTranslationTable{
  ['yuqi'] = '隅泣',
  ['yuqi1'] = '距离',
  ['yuqi2'] = '观看牌数',
  ['yuqi3'] = '交给受伤角色牌数',
  ['yuqi4'] = '自己获得牌数',
  ['#yuqi'] = '隅泣：请分配卡牌，余下的牌置于牌堆顶',
  [':yuqi'] = '每回合限两次，当一名角色受到伤害后，若你与其距离0或者更少，你可以观看牌堆顶的3张牌，将其中至多1张交给受伤角色，至多1张自己获得，剩余的牌放回牌堆顶。',
  ['$yuqi1'] = '孤影独泣，困于隅角。',
  ['$yuqi2'] = '向隅而泣，黯然伤感。',
}

yuqi:addEffect(fk.Damaged, {
  times = function(self)
    return 2 - self.player:usedSkillTimes(yuqi.name)
  end,
  can_trigger = function(event, target, player, data)
    return player:hasSkill(yuqi.name) and not target.dead and player:usedSkillTimes(yuqi.name) < 2 and
      (target == player or player:distanceTo(target) <= player:getMark("yuqi1"))
  end,
  on_use = function(event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local n1, n2, n3 = player:getMark("yuqi2") + 3, player:getMark("yuqi3") + 1, player:getMark("yuqi4") + 1
    if n1 < 2 and n2 < 1 and n3 < 1 then
      return false
    end
    local cards = U.turnOverCardsFromDrawPile(player, n1, yuqi.name, false)
    local result = room:askToArrangeCards(player, {
      skill_name = yuqi.name,
      card_map = {cards, "Top", target.general, player.general},
      prompt = "#yuqi",
      box_size = 0,
      max_limit = {n1, n2, n3},
      min_limit = {0, 1, 1}
    })
    local top, bottom = result[2], result[3]
    local moveInfos = {}
    if #top > 0 then
      table.insert(moveInfos, {
        ids = top,
        to = target.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonGive,
        proposer = player.id,
        skillName = yuqi.name,
        moveVisible = false,
        visiblePlayers = player.id,
      })
    end
    if #bottom > 0 then
      table.insert(moveInfos, {
        ids = bottom,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        moveVisible = false,
        skillName = yuqi.name,
      })
    end
    room:moveCards(table.unpack(moveInfos))
    U.returnCardsToDrawPile(player, cards, yuqi.name, true, false)
  end,

  on_acquire = function (self, player, is_start)
    local room = player.room
    room:setPlayerMark(player, "yuqi1", 0)
    room:setPlayerMark(player, "yuqi2", 0)
    room:setPlayerMark(player, "yuqi3", 0)
    room:setPlayerMark(player, "yuqi4", 0)
    room:setPlayerMark(player, "@" .. yuqi.name, {0, 3, 1, 1})
  end,
  on_lose = function (self, player, is_death)
    local room = player.room
    room:setPlayerMark(player, "yuqi1", 0)
    room:setPlayerMark(player, "yuqi2", 0)
    room:setPlayerMark(player, "yuqi3", 0)
    room:setPlayerMark(player, "yuqi4", 0)
    room:setPlayerMark(player, "@" .. yuqi.name, 0)
  end,
})

return yuqi
