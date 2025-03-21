local lieqiong = fk.CreateSkill {
  name = "lieqiong"
}

Fk:loadTranslationTable{
  ["lieqiong"] = "裂穹",
  ["lieqiong_upper_limb"] = "力烽：令其随机弃置一半手牌（向上取整）",
  ["lieqiong_lower_limb"] = "地机：令其下次受到伤害+1直到其回合结束",
  ["lieqiong_chest"] = "中枢：令其使用下一张牌失效直到其回合结束",
  ["lieqiong_abdomen"] = "气海：令其不能使用<font color='red'>♥</font>牌直到其回合结束",
  ["lieqiong_head"] = "天冲：令其失去所有体力，若其死亡你加1体力上限",
  ["#lieqiong-choose"] = "裂穹：你可“击伤” %dest 的其中一个部位",
  ["@@lieqiong_lower_limb"] = "地机:受伤+1",
  ["@@lieqiong_chest"] = "中枢:牌无效",
  ["@@lieqiong_abdomen"] = "气海:禁<font color='red'>♥</font>",
  ["#lieqiong_trigger"] = "裂穹",
  ["#lieqiong_prohibit"] = "裂穹",
  [":lieqiong"] = "当你对其他角色造成伤害后，你可以选择以下任一部位进行“击伤”：<br>力烽：令其随机弃置一半手牌（向上取整）。<br>地机：令其下次受到伤害+1直到其回合结束。<br>中枢：令其使用下一张牌失效直到其回合结束。<br>气海：令其不能使用<font color='red'>♥</font>牌直到其回合结束。<br>若你本回合击伤过该角色，则额外出现“天冲”选项。<br>天冲：令其失去所有体力，然后若其死亡，则你加1点体力上限。",
  ["$lieqiong1"] = "横眉蔑风雨，引弓狩天狼。",
  ["$lieqiong2"] = "一箭出，万军毙！",
}

lieqiong:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return target == player and data.to ~= player and data.to:isAlive() and player:hasSkill(lieqiong.name)
  end,
  on_cost = function (self, event, target, player, data)
    local choices = {
      "lieqiong_upper_limb",
      "lieqiong_lower_limb",
      "lieqiong_chest",
      "lieqiong_abdomen",
    }

    local victim = data.to
    if table.contains(player:getTableMark("lieqiong_hitter-turn"), victim.id) then
      table.insert(choices, 1, "lieqiong_head")
    end

    local results = player.room:askToChoices(player, {
      choices = choices,
      min_num = 1,
      max_num = 1,
      skill_name = lieqiong.name,
      prompt = "#lieqiong-choose::" .. victim.id
    })
    if #results > 0 then
      event:setCostData(self, {tos = {data.to.id}, choice = results[1]})
      return true
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local victim = data.to
    if not victim:isAlive() then
      return false
    end

    room:addTableMarkIfNeed(player, "lieqiong_hitter-turn", victim.id)

    local choice = event:getCostData(self).choice
    if choice == "lieqiong_head" and victim.hp > 0 then
      room:loseHp(victim, victim.hp, lieqiong.name)
      if victim.dead then
        room:changeMaxHp(player, 1)
      end
    elseif choice == "lieqiong_upper_limb" then
      local toDiscard = table.random(victim:getCardIds("h"), math.ceil(#victim:getCardIds("h") / 2))
      if #toDiscard > 0 then
        room:throwCard(toDiscard, lieqiong.name, victim, victim)
      end
    else
      room:setPlayerMark(victim, "@@" .. choice, 1)
    end
  end,
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      table.find(
        {
          "@@lieqiong_lower_limb",
          "@@lieqiong_chest",
          "@@lieqiong_abdomen",
        },
        function(markName) return player:getMark(markName) ~= 0 end
      )
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, markName in ipairs({ "@@lieqiong_lower_limb", "@@lieqiong_chest", "@@lieqiong_abdomen" }) do
      if player:getMark(markName) ~= 0 then
        room:setPlayerMark(player, markName, 0)
      end
    end
  end,
})

lieqiong:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:getMark("@@lieqiong_chest") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:setPlayerMark(player, "@@lieqiong_chest", 0)
      if data.toCard then
        data.toCard = nil
      else
        data.tos = {}
      end
    else
      room:setPlayerMark(player, "@@lieqiong_lower_limb", 0)
      data.damage = data.damage + 1
    end
  end,
})

lieqiong:addEffect(fk.DamageInflicted, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@lieqiong_lower_limb") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:setPlayerMark(player, "@@lieqiong_chest", 0)
      if data.toCard then
        data.toCard = nil
      else
        data.tos = {}
      end
    else
      room:setPlayerMark(player, "@@lieqiong_lower_limb", 0)
      data.damage = data.damage + 1
    end
  end,
})

lieqiong:addEffect("prohibit", {
  name = "#lieqiong_prohibit",
  prohibit_use = function(self, player, card)
    return
      player:getMark("@@lieqiong_abdomen") > 0 and card.suit == Card.Heart
  end,
})

return lieqiong
