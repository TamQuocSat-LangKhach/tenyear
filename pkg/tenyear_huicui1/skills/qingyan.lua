local qingyan = fk.CreateSkill {
  name = "qingyan"
}

Fk:loadTranslationTable{
  ['qingyan'] = '清严',
  ['#qingyan-invoke'] = '清严：你可以将手牌摸至体力上限',
  ['#qingyan-card'] = '清严：你可以弃置一张手牌令手牌上限+1',
  [':qingyan'] = '每回合限两次，当你成为其他角色使用黑色牌的目标后，若你的手牌数：小于体力值，你可将手牌摸至体力上限；不小于体力值，你可以弃置一张手牌令手牌上限+1。',
  ['$qingyan1'] = '清风盈大袖，严韵久长存。',
  ['$qingyan2'] = '至清之人无徒，唯余雁阵惊寒。',
}

qingyan:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingyan) and data.card.color == Card.Black and data.from ~= player.id and
      player:usedSkillTimes(qingyan.name, Player.HistoryTurn) < 2
  end,
  on_cost = function(self, event, target, player, data)
    if player:getHandcardNum() < math.min(player.hp, player.maxHp) then
      if player.room:askToSkillInvoke(player, {skill_name = qingyan.name, prompt = "#qingyan-invoke"}) then
        event:setCostData(qingyan, {"draw"})
        return true
      end
    else
      local card = player.room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = qingyan.name,
        cancelable = true,
        prompt = "#qingyan-card",
        skip = true
      })
      if #card > 0 then
        event:setCostData(qingyan, {"discard", card})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost_data = event:getCostData(qingyan)
    if cost_data[1] == "discard" then
      room:throwCard(cost_data[2], qingyan.name, player, player)
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
    else
      player:drawCards(player.maxHp - player:getHandcardNum(), qingyan.name)
    end
  end,
})

return qingyan
