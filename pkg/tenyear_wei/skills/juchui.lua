local juchui = fk.CreateSkill {
  name = "juchui",
  tags = { Skill.Combo },
}

Fk:loadTranslationTable{
  ["juchui"] = "据陲",
  [":juchui"] = "连招技（装备牌+锦囊牌），你可以选择其中一名目标角色，若其体力上限：不大于你，你令其失去或回复1点体力；"..
    "大于你，你选择一种牌的类别，获得牌堆中一张此类别的牌且其本回合不能使用此类别的牌。",

  ["#juchui-choose"] = "据陲：你可以选择一名目标角色，根据双方体力上限执行效果",
  ["#juchui-max"] = "据陲：选择一种类别，你获得一张此类别牌，且令 %dest 本回合不能使用",
  ["#juchui-min"] = "据陲：选择令 %dest 执行的效果",
  ["@juchui_limit-turn"] = "据陲",

  ["$juchui1"] = "我不击金柝，胡月何敢升！",
  ["$juchui2"] = "这千里凉州，我董卓便是天！"
}

juchui:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(juchui.name) and
      data.extra_data and data.extra_data.combo_skill and data.extra_data.combo_skill[juchui.name] and  --先随便弄个记录，之后再改
      table.find(data.tos, function (p)
        return not p.dead
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(data.tos, function (p)
      return not p.dead
    end)
    targets = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = juchui.name,
      prompt = "#juchui-choose",
      cancelable = true,
      no_indicate = true,
    })
    if #targets > 0 then
      local to = targets[1]
      local choice
      if to.maxHp > player.maxHp then
        choice = room:askToChoice(player, {
          choices = {"basic", "trick", "equip"},
          skill_name = juchui.name,
          prompt = "#juchui-max::" .. to.id,
        })
      else
        choice = room:askToChoice(player, {
          choices = {"recover", "loseHp"},
          skill_name = juchui.name,
          prompt = "#juchui-min::"..to.id,
        })
      end
      event:setCostData(self, {tos = {to}, choice = choice})
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local choice = event:getCostData(self).choice
    if choice == "recover" then
      room:recover {
        who = to,
        num = 1,
        recoverBy = player,
        skillName = juchui.name,
      }
    elseif choice == "loseHp" then
      room:loseHp(to, 1, juchui.name)
    else
      local cards = room:getCardsFromPileByRule(".|.|.|.|.|" .. choice)
      if #cards > 0 then
        room:obtainCard(player, cards, false, fk.ReasonJustMove, player, juchui.name)
      end
      if not to.dead then
        room:addTableMarkIfNeed(to, "@juchui_limit-turn", choice.."_char")
      end
    end
  end,
})

juchui:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(juchui.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if data.card.type == Card.TypeTrick then
      if player:getMark(juchui.name) > 0 then
        data.extra_data = data.extra_data or {}
        data.extra_data.combo_skill = data.extra_data.combo_skill or {}
        data.extra_data.combo_skill[juchui.name] = true
      end
    elseif data.card.type == Card.TypeEquip then
      room:setPlayerMark(player, juchui.name, 1)
    else
      room:setPlayerMark(player, juchui.name, 0)
    end
  end,
})

juchui:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card and table.contains(player:getTableMark("@juchui_limit-turn"), card:getTypeString().."_char")
  end,
})

return juchui
