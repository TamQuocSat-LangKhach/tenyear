local qingyan = fk.CreateSkill {
  name = "qingyan",
}

Fk:loadTranslationTable{
  ["qingyan"] = "清严",
  [":qingyan"] = "每回合限两次，当你成为其他角色使用黑色牌的目标后，若你的手牌数：小于体力值，你可以将手牌摸至体力上限；不小于体力值，"..
  "你可以弃置一张手牌令手牌上限+1。",

  ["#qingyan-draw"] = "清严：你可以将手牌摸至体力上限",
  ["#qingyan-discard"] = "清严：你可以弃置一张手牌，令手牌上限+1",

  ["$qingyan1"] = "清风盈大袖，严韵久长存。",
  ["$qingyan2"] = "至清之人无徒，唯余雁阵惊寒。",
}

qingyan:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(qingyan.name) and
      data.card.color == Card.Black and data.from ~= player and
      player:usedSkillTimes(qingyan.name, Player.HistoryTurn) < 2 then
      if player:getHandcardNum() < math.min(player.hp, player.maxHp) then
        return true
      elseif player:getHandcardNum() >= player.hp then
        return not player:isKongcheng()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if player:getHandcardNum() < math.min(player.hp, player.maxHp) then
      if room:askToSkillInvoke(player, {
        skill_name = qingyan.name,
        prompt = "#qingyan-draw",
      }) then
        event:setCostData(self, {choice = "draw"})
        return true
      end
    elseif player:getHandcardNum() >= player.hp then
      local card = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = qingyan.name,
        cancelable = true,
        prompt = "#qingyan-discard",
        skip = true,
      })
      if #card > 0 then
        event:setCostData(self, {choice = "discard", cards = card})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self).choice == "discard" then
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
      room:throwCard(event:getCostData(self).cards, qingyan.name, player, player)
    else
      player:drawCards(player.maxHp - player:getHandcardNum(), qingyan.name)
    end
  end,
})

return qingyan
