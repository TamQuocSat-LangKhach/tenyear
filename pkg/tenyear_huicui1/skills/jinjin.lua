local jinjin = fk.CreateSkill {
  name = "jinjin"
}

Fk:loadTranslationTable{
  ['jinjin'] = '矜谨',
  ['#jinjin-invoke'] = '矜谨：你可将手牌上限（当前为%arg）重置为体力值',
  ['#jinjin-discard'] = '矜谨：请弃置至多 %arg 张牌，每少弃置一张 %src 便摸一张牌',
  [':jinjin'] = '每回合限两次，当你造成或受到伤害后，你可以将你的手牌上限重置为当前体力值。若如此做，伤害来源可以弃置至多X张牌（X为你因此变化的手牌上限数且至少为1），然后其每少弃置一张，你便摸一张牌。',
  ['$jinjin1'] = '螟蛉终非麒麟，不可气盛自矜。',
  ['$jinjin2'] = '我姓非曹，可敬人，不可欺人。',
}

jinjin:addEffect({fk.Damage, fk.Damaged}, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jinjin.name) and player:usedSkillTimes(jinjin.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = jinjin.name,
      prompt = "#jinjin-invoke:::"..player:getMaxCards()
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = math.max(1, math.abs(player:getMaxCards() - player.hp))
    room:setPlayerMark(player, MarkEnum.AddMaxCards, 0)
    room:setPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 0)
    room:setPlayerMark(player, MarkEnum.MinusMaxCards, 0)
    room:setPlayerMark(player, MarkEnum.MinusMaxCardsInTurn, 0)
    local new_n = player:getMaxCards() - player.hp
    if new_n > 0 then
      room:setPlayerMark(player, MarkEnum.MinusMaxCards, new_n)
    else
      room:setPlayerMark(player, MarkEnum.AddMaxCards, -new_n)
    end
    room:broadcastProperty(player, "MaxCards")
    local data = event.data
    if data.from and not data.from.dead then
      local x = #room:askToDiscard(data.from, {
        min_num = 1,
        max_num = n,
        cancelable = true,
        prompt = "#jinjin-discard:"..player.id.."::"..n
      })
      if x < n and not player.dead then
        player:drawCards(n - x, jinjin.name)
      end
    end
  end,
})

return jinjin
