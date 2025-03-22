local fangtong = fk.CreateSkill {
  name = "fangtong",
}

Fk:loadTranslationTable{
  ["fangtong"] = "方统",
  [":fangtong"] = "结束阶段，你可以弃置一张牌，然后将至少一张“方”置入弃牌堆。若此牌与你以此法置入弃牌堆的所有“方”的点数之和为36，"..
  "你对一名其他角色造成3点雷电伤害。",

  ["zhangliang_fang"] = "方",
  ["#fangtong-invoke"] = "方统：你可以弃置一张牌发动“方统”",
  ["#fangtong-discard"] = "方统：将至少一张“方”置入弃牌堆，还差%arg点则造成3点雷电伤害！",
  ["#fangtong-choose"] = "方统：对一名角色造成3点雷电伤害！",

  ["$fangtong1"] = "统领方队，为民意所举！",
  ["$fangtong2"] = "三十六方，必为大统！",
}

fangtong:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fangtong.name) and player.phase == Player.Finish and
      #player:getPile("zhangliang_fang") > 0 and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = fangtong.name,
      cancelable = true,
      prompt = "#fangtong-invoke",
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n1 = Fk:getCardById(event:getCostData(self).cards[1]).number
    room:throwCard(event:getCostData(self).cards, fangtong.name, player, player)
    if player.dead or #player:getPile("zhangliang_fang") == 0 then return end
    local cards = room:askToCards(player, {
      skill_name = fangtong.name,
      min_num = 1,
      max_num = 999,
      include_equip = false,
      pattern = ".|.|.|zhangliang_fang",
      prompt = "#fangtong-discard:::"..(36 - n1),
      expand_pile = "zhangliang_fang",
      cancelable = false,
    })
    local yes = false
    for _, id in ipairs(cards) do
      n1 = n1 + Fk:getCardById(id).number
    end
    yes = n1 == 36
    room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, fangtong.name, nil, true, player)
    if not yes or player.dead or #room:getOtherPlayers(player, false) == 0 then return end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = fangtong.name,
      prompt = "#fangtong-choose",
      cancelable = false,
    })[1]
    room:damage {
      from = player,
      to = to,
      damage = 3,
      damageType = fk.ThunderDamage,
      skillName = fangtong.name,
    }
  end,
})

return fangtong
