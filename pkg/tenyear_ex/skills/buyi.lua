local buyi = fk.CreateSkill {
  name = "ty_ex__buyi",
}

Fk:loadTranslationTable{
  ["ty_ex__buyi"] = "补益",
  [":ty_ex__buyi"] = "当一名角色进入濒死状态时，你可以展示其一张手牌，若不为基本牌，则其弃置此牌并回复1点体力。若其因此弃置最后一张手牌，"..
  "其摸一张牌。",

  ["#ty_ex__buyi-invoke"] = "补益：你可以展示 %dest 的一张手牌，若为非基本牌则其弃置并回复1点体力",

  ["$ty_ex__buyi1"] = "有老身在，阁下勿忧。",
  ["$ty_ex__buyi2"] = "如此佳婿，谁敢伤之？",
}

buyi:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(buyi.name) and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = buyi.name,
      prompt = "#ty_ex__buyi-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askToChooseCard(player, {
      target = target,
      flag = "h",
      skill_name = buyi.name,
    })
    target:showCards(id)
    if target.dead then return end
    local yes = target:getHandcardNum() == 1
    if Fk:getCardById(id).type ~= Card.TypeBasic and table.contains(target:getCardIds("h"), id) and
      not target:prohibitDiscard(id) then
      room:throwCard(id, buyi.name, target, target)
      if target:isWounded() and not target.dead then
        room:recover{
          who = target,
          num = 1,
          recoverBy = player,
          skillName = buyi.name,
        }
      end
      if yes and not target.dead then
        target:drawCards(1, buyi.name)
      end
    end
  end,
})

return buyi
