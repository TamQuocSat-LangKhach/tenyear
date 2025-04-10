local sitian = fk.CreateSkill {
  name = "ty__sitian",
}

Fk:loadTranslationTable{
  ["ty__sitian"] = "司天",
  [":ty__sitian"] = "出牌阶段，你可以弃置两张不同花色的手牌，然后改变天气（从两个选项中选择一项）：<br>"..
  "烈日：对其他角色各造成1点火焰伤害；<br>雷电：所有其他角色各进行一次【闪电】判定；<br>"..
  "大浪：所有其他角色弃置装备区所有牌（没有装备则失去1点体力）；<br>"..
  "暴雨：弃置一名角色所有手牌（没有手牌则失去1点体力）；<br>"..
  "大雾：所有其他角色使用的下一张基本牌无效。",

  ["#ty__sitian"] = "司天：弃置两张不同花色的手牌，执行一个天气效果",
  ["#ty__sitian-choice"] = "司天：选择执行的一项",
  ["#sitian-choose"] = "暴雨：令一名角色弃置所有手牌，若其没有手牌则改为失去1点体力。",
  ["sitian1"] = "烈日",
  [":sitian1"] = "对其他角色各造成1点火焰伤害",
  ["sitian2"] = "雷电",
  [":sitian2"] = "所有其他角色各进行一次【闪电】判定",
  ["sitian3"] = "大浪",
  [":sitian3"] = "所有其他角色弃置装备区所有牌（没有装备则失去1点体力）",
  ["sitian4"] = "暴雨",
  [":sitian4"] = "弃置一名角色所有手牌（没有手牌则失去1点体力）",
  ["sitian5"] = "大雾",
  [":sitian5"] = "所有其他角色使用的下一张基本牌无效",
  ["@@sitian_dawu"] = "雾",

  ["$ty__sitian1"] = "观众朋友大家好，欢迎收看天气预报！",
  ["$ty__sitian2"] = "这一喷嚏，不知要掀起多少狂风暴雨。",
}

sitian:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty__sitian",
  card_num = 2,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    if #selected < 2 and table.contains(player:getCardIds("h"), to_select) and Fk:getCardById(to_select).suit ~= Card.NoSuit and
      not player:prohibitDiscard(to_select) then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(selected[1]), true)
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:throwCard(effect.cards, sitian.name, player, player)
    local targets = room:getOtherPlayers(player)
    if player.dead or #targets == 0 then return end
    local choices = table.random({"sitian1", "sitian2", "sitian3", "sitian4", "sitian5"}, 2)
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = sitian.name,
      prompt = "#ty__sitian-choice",
      detailed = true,
    })
    if choice ~= "sitian4" then
      room:doIndicate(player, targets)
    end
    if choice == "sitian1" then
      for _, p in ipairs(targets) do
        if not p.dead then
          room:damage{
            from = player,
            to = p,
            damage = 1,
            damageType = fk.FireDamage,
            skillName = sitian.name,
          }
        end
      end
    end
    if choice == "sitian2" then
      for _, p in ipairs(targets) do
        if not p.dead then
          local judge = {
            who = p,
            reason = "lightning",
            pattern = ".|2~9|spade",
          }
          room:judge(judge)
          if judge:matchPattern() then
            room:damage{
              to = p,
              damage = 3,
              damageType = fk.ThunderDamage,
              skillName = sitian.name,
            }
          end
        end
      end
    end
    if choice == "sitian3" then
      for _, p in ipairs(targets) do
        if not p.dead then
          if #p:getCardIds("e") > 0 then
            p:throwAllCards("e", sitian.name)
          else
            room:loseHp(p, 1, sitian.name)
          end
        end
      end
    end
    if choice == "sitian4" then
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#sitian-choose",
        skill_name = sitian.name,
        cancelable = true,
      })
      if #to > 0 then
        to = to[1]
        if not to:isKongcheng() then
          to:throwAllCards("h", sitian.name)
        else
          room:loseHp(to, 1, sitian.name)
        end
      end
    end
    if choice == "sitian5" then
      for _, p in ipairs(targets) do
        if not p.dead then
          room:setPlayerMark(p, "@@sitian_dawu", 1)
        end
      end
    end
  end,
})

sitian:addEffect(fk.PreCardEffect, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target and target:getMark("@@sitian_dawu") > 0 and data.card.type == Card.TypeBasic
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(target, "@@sitian_dawu", 0)
    data.nullified = true
  end,
})

return sitian
