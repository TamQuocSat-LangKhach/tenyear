local yanzhengn = fk.CreateSkill {
  name = "yanzhengn",
}

Fk:loadTranslationTable{
  ["yanzhengn"] = "言政",
  [":yanzhengn"] = "准备阶段，若你的手牌数大于1，你可以选择一张手牌并弃置其余的牌，然后对至多等于弃置牌数的角色各造成1点伤害。",

  ["#yanzhengn-invoke"] = "言政：你可以选择保留一张手牌，弃置其余的手牌，对至多弃牌数的角色各造成1点伤害",
  ["#yanzhengn-choose"] = "言政：对至多%arg名角色各造成1点伤害",
}

yanzhengn:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yanzhengn.name) and player.phase == Player.Start and
      player:getHandcardNum() > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = table.filter(player:getCardIds("h"), function (id)
      return table.find(player:getCardIds("h"), function (id2)
        return id ~= id2 and not player:prohibitDiscard(id2)
      end) ~= nil
    end)
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = yanzhengn.name,
      pattern = tostring(Exppattern{ id = ids }),
      prompt = "#yanzhengn-invoke",
      cancelable = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = table.filter(player:getCardIds("h"), function (id)
      return id ~= event:getCostData(self).cards[1] and not player:prohibitDiscard(id)
    end)
    room:throwCard(ids, yanzhengn.name, player, player)
    if player.dead then return end
    local tos = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = #ids,
      targets = room.alive_players,
      skill_name = yanzhengn.name,
      prompt = "#yanzhengn-choose:::"..#ids,
      cancelable = false,
    })
    room:sortByAction(tos)
    for _, p in ipairs(tos) do
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = yanzhengn.name,
        }
      end
    end
  end,
})

return yanzhengn
