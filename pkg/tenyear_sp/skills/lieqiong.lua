local lieqiong = fk.CreateSkill {
  name = "lieqiong",
}

Fk:loadTranslationTable{
  ["lieqiong"] = "裂穹",
  [":lieqiong"] = "当你对其他角色造成伤害后，你可以选择以下任一部位进行“击伤”：<br>"..
  "力烽：令其随机弃置一半手牌（向上取整）；<br>地机：令其下次受到伤害+1直到其回合结束；<br>"..
  "中枢：令其使用下一张牌失效直到其回合结束。<br>气海：令其不能使用<font color='red'>♥</font>牌直到其回合结束。<br>"..
  "若你本回合击伤过该角色，则额外出现“天冲”：令其失去所有体力，然后若其死亡，则你加1点体力上限。",

  ["lieqiong_upper_limb"] = "力烽：令其随机弃置一半手牌（向上取整）",
  ["lieqiong_lower_limb"] = "地机：令其下次受到伤害+1直到其回合结束",
  ["lieqiong_chest"] = "中枢：令其使用下一张牌失效直到其回合结束",
  ["lieqiong_abdomen"] = "气海：令其不能使用<font color='red'>♥</font>牌直到其回合结束",
  ["lieqiong_head"] = "天冲：令其失去所有体力，若其死亡你加1体力上限",
  ["#lieqiong-choose"] = "裂穹：你可“击伤” %dest 的其中一个部位",
  ["@@lieqiong_lower_limb"] = "地机:受伤+1",
  ["@@lieqiong_chest"] = "中枢:牌无效",
  ["@@lieqiong_abdomen"] = "气海:禁<font color='red'>♥</font>",

  ["$lieqiong1"] = "横眉蔑风雨，引弓狩天狼。",
  ["$lieqiong2"] = "一箭出，万军毙！",
}

lieqiong:addEffect(fk.Damage, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lieqiong.name) and data.to ~= player and not data.to.dead
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = {
      "lieqiong_upper_limb",
      "lieqiong_lower_limb",
      "lieqiong_chest",
      "lieqiong_abdomen",
    }
    local to = data.to
    if table.contains(player:getTableMark("lieqiong_hitter-turn"), to.id) then
      table.insert(choices, 1, "lieqiong_head")
    end
    local results = room:askToChoices(player, {
      choices = choices,
      min_num = 1,
      max_num = 1,
      skill_name = lieqiong.name,
      prompt = "#lieqiong-choose::" .. to.id,
    })
    if #results > 0 then
      event:setCostData(self, {tos = {data.to}, choice = results[1]})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.to
    room:addTableMarkIfNeed(player, "lieqiong_hitter-turn", to.id)

    local choice = event:getCostData(self).choice
    if choice == "lieqiong_head" and to.hp > 0 then
      room:loseHp(to, to.hp, lieqiong.name)
      if to.dead then
        room:changeMaxHp(player, 1)
      end
    elseif choice == "lieqiong_upper_limb" then
      local cards = table.filter(to:getCardIds("h"), function (id)
        return not to:prohibitDiscard(id)
      end)
      if #cards > 0 then
        room:throwCard(table.random(cards, (to:getHandcardNum() + 1) // 2), lieqiong.name, to, to)
      end
    else
      room:setPlayerMark(to, "@@" .. choice, 1)
    end
  end,
})

lieqiong:addEffect(fk.TurnEnd, {
  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, name in ipairs({"@@lieqiong_lower_limb", "@@lieqiong_chest", "@@lieqiong_abdomen"}) do
      room:setPlayerMark(player, name, 0)
    end
  end,
})

lieqiong:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@lieqiong_chest") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@lieqiong_chest", 0)
    data.toCard = nil
    data:removeAllTargets()
  end,
})

lieqiong:addEffect(fk.DamageInflicted, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@lieqiong_lower_limb") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@lieqiong_lower_limb", 0)
    data:changeDamage(1)
  end,
})

lieqiong:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card and player:getMark("@@lieqiong_abdomen") > 0 and card.suit == Card.Heart
  end,
})

return lieqiong
