local zhenyi = fk.CreateSkill {
  name = "zhenyi",
}

Fk:loadTranslationTable{
  ["zhenyi"] = "真仪",
  [":zhenyi"] = "你可以在以下时机弃置相应的标记来发动以下效果：<br>"..
  "当一张判定牌生效前，你可以弃置“紫微”，将判定结果改为♠5或<font color='red'>♥5</font>；<br>"..
  "当你于回合外需要使用【桃】时，你可以弃置“后土”，将一张牌当【桃】使用；<br>"..
  "当你造成伤害时，你可以弃置“玉清”，此伤害+1；<br>"..
  "当你受到属性伤害后，你可以弃置“勾陈”，从牌堆中随机获得三种类型的牌各一张。",

  ["@@faluclub"] = "♣后土",
  ["@@faluspade"] = "♠紫微",
  ["@@faluheart"] = "<font color='red'>♥</font>玉清",
  ["@@faludiamond"] = "<font color='red'>♦</font>勾陈",
  ["#zhenyi1"] = "真仪：你可以弃置♠紫微，将 %dest 的“%arg”判定结果改为♠5或<font color=>♥5</font>",
  ["#zhenyi2"] = "真仪：你可以弃置♣后土，将一张牌当【桃】使用",
  ["#zhenyi3"] = "真仪：你可以弃置<font color='red'>♥</font>玉清，对 %dest 造成的伤害+1",
  ["#zhenyi4"] = "真仪：你可以弃置<font color='red'>♦</font>勾陈，从牌堆中随机获得三种类型的牌各一张",
  ["zhenyi_spade"] = "将判定结果改为♠5",
  ["zhenyi_heart"] = "将判定结果改为<font color='red'>♥5</font>",

  ["$zhenyi1"] = "不疾不徐，自爱自重。",
  ["$zhenyi2"] = "紫薇星辰，斗数之仪。",
}

zhenyi:addEffect("viewas", {
  anim_type = "support",
  pattern = "peach",
  prompt = "#zhenyi2",
  card_num = 1,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  before_use = function(self, player)
    player.room:removePlayerMark(player, "@@faluclub", 1)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("peach")
    c.skillName = zhenyi.name
    c:addSubcard(cards[1])
    return c
  end,
  enabled_at_play = Util.FalseFunc,
  enabled_at_response = function(self, player)
    return Fk:currentRoom().current ~= player and player:getMark("@@faluclub") > 0
  end,
})

zhenyi:addEffect(fk.AskForRetrial, {
  anim_type = "control",
  can_trigger = function (self, event, target, player, data)
    return player:hasSkill(zhenyi.name) and player:getMark("@@faluspade") > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"zhenyi_spade", "zhenyi_heart", "Cancel"},
      skill_name = zhenyi.name,
      prompt = "#zhenyi1::"..target.id..":"..data.reason,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {tos = {target}, choice = choice})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@@faluspade", 1)
    local choice = event:getCostData(self).choice
    local new_card = Fk:cloneCard(data.card.name, choice == "zhenyi_spade" and Card.Spade or Card.Heart, 5)
    new_card.skillName = zhenyi.name
    new_card.id = data.card.id
    data.card = new_card
    room:sendLog{
      type = "#ChangedJudge",
      from = player.id,
      to = { data.who.id },
      arg2 = new_card:toLogString(),
      arg = zhenyi.name,
    }
  end,
})
zhenyi:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(zhenyi.name) and player:getMark("@@faluheart") > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = zhenyi.name,
      prompt = "#zhenyi3::"..data.to.id,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@@faluheart", 1)
    data:changeDamage(1)
  end,
})
zhenyi:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(zhenyi.name) and
      player:getMark("@@faludiamond") > 0 and data.damageType ~= fk.NormalDamage
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhenyi.name,
      prompt = "#zhenyi4",
    })
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, "@@faludiamond", 1)
    local cards = {}
    for _, type in ipairs({"basic", "trick", "equip"}) do
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|.|.|.|"..type))
    end
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, zhenyi.name, nil, false, player)
    end
  end,
})

return zhenyi
