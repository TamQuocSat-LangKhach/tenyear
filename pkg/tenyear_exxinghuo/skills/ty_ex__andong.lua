local ty_ex__andong = fk.CreateSkill {
  name = "ty_ex__andong"
}

Fk:loadTranslationTable{
  ['ty_ex__andong'] = '安东',
  ['#ty_ex__andong-invoke'] = '安东：你可以对 %dest 发动“安东”',
  ['ty_ex__andong1'] = '防止此伤害，本回合你的<font color=>♥</font>牌不计入手牌上限',
  ['ty_ex__andong2'] = '其观看你的手牌并获得其中的<font color=>♥</font>牌',
  ['#ty_ex__andong-choice'] = '安东：选择 %src 令你执行的一项',
  ['ty_ex__andong1Ex'] = '防止此伤害，本回合其<font color=>♥</font>牌不计入手牌上限',
  ['ty_ex__andong2Ex'] = '观看其手牌并获得其中的<font color=>♥</font>牌',
  ['#ty_ex__andong2-choice'] = '安东：选择对 %dest 执行的一项',
  [':ty_ex__andong'] = '当你受到其他角色造成的伤害时，你可令伤害来源选择一项：1.防止此伤害，本回合弃牌阶段<font color=>♥</font>牌不计入手牌上限；2.观看其手牌，若其中有<font color=>♥</font>牌则你获得这些牌。若选择2且其没有手牌，则下一次发动时改为由你选择。',
  ['$ty_ex__andong1'] = '青龙映木，星出其东则天下安。',
  ['$ty_ex__andong2'] = '以身涉险，剑伐不臣而定河东。',
}

ty_ex__andong:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty_ex__andong.name) and data.from and data.from ~= player and not data.from.dead
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = ty_ex__andong.name,
      prompt = "#ty_ex__andong-invoke::" .. data.from.id
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {data.from.id})
    local choices = {"ty_ex__andong1", "ty_ex__andong2"}
    local to = data.from
    local prompt = "#ty_ex__andong-choice:" .. player.id
    if player:getMark(ty_ex__andong.name) > 0 then
      choices = {"ty_ex__andong1Ex", "ty_ex__andong2Ex"}
      to = player
      prompt = "#ty_ex__andong2-choice::" .. data.from.id
      room:setPlayerMark(player, ty_ex__andong.name, 0)
    end
    local choice = room:askToChoice(to, {
      choices = choices,
      skill_name = ty_ex__andong.name,
      prompt = prompt
    })
    if choice[14] == "1" then
      room:setPlayerMark(data.from, "ty_ex__andong-turn", 1)
      return true
    else
      if data.from:isKongcheng() then
        room:setPlayerMark(player, ty_ex__andong.name, 1)
        return
      end
      U.viewCards(player, data.from:getCardIds("h"), ty_ex__andong.name)
      local cards = table.filter(data.from:getCardIds("h"), function(id) return Fk:getCardById(id).suit == Card.Heart end)
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, ty_ex__andong.name, nil, true, player.id)
      end
    end
  end,
})

ty_ex__andong:addEffect('maxcards', {
  exclude_from = function(self, player, card)
    return player:getMark("ty_ex__andong-turn") > 0 and card.suit == Card.Heart
  end,
})

return ty_ex__andong
