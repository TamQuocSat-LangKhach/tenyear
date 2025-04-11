local pojun = fk.CreateSkill {
  name = "ty_ex__pojun",
}

Fk:loadTranslationTable{
  ["ty_ex__pojun"] = "破军",
  [":ty_ex__pojun"] = "当你使用【杀】指定一个目标后，你可以将其至多X张牌移出游戏直到回合结束（X为其体力值），若其中有：装备牌，"..
  "你弃置其中一张；锦囊牌，你摸一张牌。",

  ["#ty_ex__pojun-invoke"] = "破军：你可以扣置 %dest 至多%arg张牌",
  ["$ty_ex__pojun"] = "破军",
  ["#ty_ex__pojun-discard"] = "破军：弃置其中一张装备",

  ["$ty_ex__pojun1"] = "奋身出命，为国建功！",
  ["$ty_ex__pojun2"] = "披甲持戟，先登陷陈！",
}

pojun:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(pojun.name) and data.card.trueName == "slash" and
      player.phase == Player.Play and not data.to.dead and data.to.hp > 0 and not data.to:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = pojun.name,
      prompt = "#ty_ex__pojun-invoke::"..data.to.id..":"..data.to.hp,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToChooseCards(player, {
      skill_name = pojun.name,
      target = data.to,
      flag = "he",
      min = 1,
      max = data.to.hp,
    })
    data.to:addToPile("$ty_ex__pojun", cards, false, pojun.name, player)
    if player.dead or data.to.dead then return end
    local equips = table.filter(cards, function (id)
      return Fk:getCardById(id).type == Card.TypeEquip
    end)
    if #equips > 0 then
      local card = room:askToChooseCard(player, {
        target = data.to,
        flag = { card_data = { { pojun.name, equips } }},
        skill_name = pojun.name,
        prompt = "#ty_ex__pojun-discard",
      })
      room:throwCard(card, pojun.name, data.to, player)
    end
    if table.find(cards, function (id)
      return Fk:getCardById(id).type == Card.TypeTrick
    end) and not player.dead then
      player:drawCards(1, pojun.name)
    end
  end,
})

pojun:addEffect(fk.TurnEnd, {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and #player:getPile("$ty_ex__pojun") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(player:getPile("$ty_ex__pojun"), Player.Hand, player, fk.ReasonJustMove, pojun.name)
  end,
})

return pojun
