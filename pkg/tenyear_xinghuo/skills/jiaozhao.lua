local jiaozhao = fk.CreateSkill {
  name = "ty_ex__jiaozhao",
  dynamic_desc = function (self, player)
    if player:getMark("ty_ex__danxin") > 0 then
      return "ty_ex__jiaozhao_update"..player:getMark("ty_ex__danxin")
    end
  end,
}

Fk:loadTranslationTable{
  ["ty_ex__jiaozhao"] = "矫诏",
  [":ty_ex__jiaozhao"] = "出牌阶段限一次，你可以展示一张手牌并选择一名距离最近的其他角色，该角色声明一种基本牌或普通锦囊牌的牌名，"..
  "本回合你可以将此牌当声明的牌使用（不能指定自己为目标）。",

  [":ty_ex__jiaozhao_update1"] = "出牌阶段限一次，你可以展示一张手牌并声明一种基本牌或普通锦囊牌的牌名，"..
  "本回合你可以将此牌当声明的牌使用（不能指定自己为目标）。",
  [":ty_ex__jiaozhao_update2"] = "出牌阶段，你可以展示一张手牌并声明一种基本牌或普通锦囊牌的牌名（每阶段每种类型限一次），"..
  "本回合你可以将此牌当声明的牌使用。",

  ["#ty_ex__jiaozhao0"] = "矫诏：展示一张手牌，令一名角色声明一种基本牌或普通锦囊牌",
  ["#ty_ex__jiaozhao1"] = "矫诏：展示一张手牌，然后声明一种基本牌或普通锦囊牌",
  ["#ty_ex__jiaozhao2"] = "矫诏：展示一张手牌，然后声明一种基本牌或普通锦囊牌",
  ["#ty_ex__jiaozhao-use"] = "矫诏：你可以将“矫诏”牌当声明的牌使用",
  ["#ty_ex__jiaozhao-choice"] = "矫诏：声明一种牌名，%src 本回合可以将%arg当此牌使用",
  ["@ty_ex__jiaozhao-inhand-turn"] = "矫诏",
  ["#ty_ex__jiaozhao-both"] = "矫诏：你可以展示一张手牌并声明一种牌，或将“矫诏”牌当声明的牌使用",
  ["#ty_ex__jiaozhao2-choice"] = "矫诏：使用这张牌，还是重新声明“矫诏”牌名？",
  ["ty_ex__jiaozhao_declare"] = "重新声明",

  ["$ty_ex__jiaozhao1"] = "事关社稷，万望阁下谨慎行事。",
  ["$ty_ex__jiaozhao2"] = "为续江山，还请爱卿仔细观之。",
}

local U = require "packages/utility/utility"

jiaozhao:addEffect("active", {
  anim_type = "special",
  prompt = function (self, player, selected_cards, selected_targets)
    if player:getMark("ty_ex__danxin") < 2 then
      if player:usedEffectTimes(jiaozhao.name, Player.HistoryPhase) == 0 then
        return "#ty_ex__jiaozhao"..player:getMark("ty_ex__danxin")
      else
        return "#ty_ex__jiaozhao-use"
      end
    else
      local choices = {}
      if table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("ty_ex__jiaozhao-inhand-turn") ~= 0
      end) then
        table.insert(choices, "#ty_ex__jiaozhao-use")
      end
      if #player:getTableMark("ty_ex__jiaozhao_types-phase") < 2 then
        table.insert(choices, "#ty_ex__jiaozhao1")
      end
      if #choices == 2 then
        return "#ty_ex__jiaozhao-both"
      elseif #choices == 1 then
        return choices[1]
      end
    end
  end,
  card_num = 1,
  can_use = function(self, player)
    if player:getMark("ty_ex__danxin") < 2 then
      if player:usedEffectTimes(jiaozhao.name, Player.HistoryPhase) == 0 then
        return true
      else
        return table.find(player:getCardIds("h"), function (id)
          return Fk:getCardById(id):getMark("ty_ex__jiaozhao-inhand-turn") ~= 0
        end)
      end
    else
      return table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("ty_ex__jiaozhao-inhand-turn") ~= 0
      end) or
      #player:getTableMark("ty_ex__jiaozhao_types-phase") < 2
    end
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and table.contains(player:getCardIds("h"), to_select) then
      if player:usedEffectTimes(jiaozhao.name, Player.HistoryPhase) == 0 or
        (player:getMark("ty_ex__danxin") == 2 and #player:getTableMark("ty_ex__jiaozhao_types-phase") < 2) then
        return true
      else
        if Fk:getCardById(to_select):getMark("ty_ex__jiaozhao-inhand-turn") ~= 0 then
          local card = Fk:cloneCard(Fk:getCardById(to_select):getMark("ty_ex__jiaozhao-inhand-turn"))
          card.skillName = jiaozhao.name
          card:addSubcard(to_select)
          return card.skill:canUse(player, card)
        end
      end
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if player:getMark("ty_ex__danxin") < 2 then
      if player:usedEffectTimes(jiaozhao.name, Player.HistoryPhase) == 0 then
        if player:getMark("ty_ex__danxin") == 0 then
          return #selected == 0 and to_select ~= player and
            table.every(Fk:currentRoom().alive_players, function (p)
              if p == player then
                return true
              else
                return to_select:distanceTo(player) <= p:distanceTo(player)
              end
            end)
        else
          return false
        end
      elseif #selected_cards == 1 then
        local card = Fk:cloneCard(Fk:getCardById(selected_cards[1]):getMark("ty_ex__jiaozhao-inhand-turn"))
        card.skillName = jiaozhao.name
        card:addSubcards(selected_cards)
        return card.skill:targetFilter(player, to_select, selected, {}, card)
      end
    elseif #selected_cards == 1 then
      local mark = Fk:getCardById(selected_cards[1]):getMark("ty_ex__jiaozhao-inhand-turn")
      if mark == 0 then
        return false
      else
        local card = Fk:cloneCard(mark)
        card.skillName = jiaozhao.name
        card:addSubcards(selected_cards)
        return card.skill:targetFilter(player, to_select, selected, {}, card)
      end
    end
  end,
  feasible = function (self, player, selected, selected_cards)
    if #selected_cards == 1 then
      if player:getMark("ty_ex__danxin") < 2 then
        if player:usedEffectTimes(jiaozhao.name, Player.HistoryPhase) == 0 then
          if player:getMark("ty_ex__danxin") == 0 then
            return #selected == 1
          else
            return #selected == 0
          end
        else
          local card = Fk:cloneCard(Fk:getCardById(selected_cards[1]):getMark("ty_ex__jiaozhao-inhand-turn"))
          card.skillName = jiaozhao.name
          card:addSubcards(selected_cards)
          return card.skill:feasible(player, selected, {}, card)
        end
      else
        local mark = Fk:getCardById(selected_cards[1]):getMark("ty_ex__jiaozhao-inhand-turn")
        if mark == 0 then
          return #selected == 0
        else
          local card = Fk:cloneCard(mark)
          card.skillName = jiaozhao.name
          card:addSubcards(selected_cards)
          if card.skill:feasible(player, selected, {}, card) then
            return true
          else
            return #selected == 0
          end
        end
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local mark = Fk:getCardById(effect.cards[1]):getMark("ty_ex__jiaozhao-inhand-turn")
    if mark == 0 then
      local target = player:getMark("ty_ex__danxin") == 0 and effect.tos[1] or player
      player:showCards(effect.cards)
      local id = effect.cards[1]
      if player.dead or target.dead or not table.contains(player:getCardIds("h"), id) then return end
      local flag = "bt"
      if #player:getTableMark("ty_ex__jiaozhao_types-phase") == 1 then
        if player:getMark("ty_ex__jiaozhao_types-phase")[1] == "b" then
          flag = "t"
        else
          flag = "b"
        end
      end
      local choice = U.askForChooseCardNames(room, target,
        Fk:getAllCardNames(flag),
        1,
        1,
        jiaozhao.name,
        "#ty_ex__jiaozhao-choice:"..player.id.."::"..Fk:getCardById(id):toLogString()
      )[1]
      room:sendLog{
        type = "#Choice",
        from = target.id,
        arg = choice,
        toast = true,
      }
      room:addTableMark(player, "ty_ex__jiaozhao_types-phase", Fk:cloneCard(choice):getTypeString()[1])
      room:setCardMark(Fk:getCardById(id), "@ty_ex__jiaozhao-inhand-turn", Fk:translate(choice))
      room:setCardMark(Fk:getCardById(id), "ty_ex__jiaozhao-inhand-turn", choice)
    else
      local card = Fk:cloneCard(Fk:getCardById(effect.cards[1]):getMark("ty_ex__jiaozhao-inhand-turn"))
      card.skillName = jiaozhao.name
      card:addSubcards(effect.cards)
      if player:getMark("ty_ex__danxin") < 2 or #player:getTableMark("ty_ex__jiaozhao_types-phase") == 2 or
        (card.skill:feasible(player, effect.tos, {}, card) and
        room:askToChoice(player, {
          choices = {"method_use", "ty_ex__jiaozhao_declare"},
          skill_name = jiaozhao.name,
          prompt = "#ty_ex__jiaozhao2-choice",
        }) == "method_use") then
        room:useCard{
          from = player,
          tos = effect.tos,
          card = card,
        }
      else
        player:showCards(effect.cards)
        local id = effect.cards[1]
        if player.dead or not table.contains(player:getCardIds("h"), id) then return end
        local flag = "bt"
        if #player:getTableMark("ty_ex__jiaozhao_types-phase") == 1 then
          if player:getMark("ty_ex__jiaozhao_types-phase")[1] == "b" then
            flag = "t"
          else
            flag = "b"
          end
        end
        local choice = U.askForChooseCardNames(room, player,
          Fk:getAllCardNames(flag),
          1,
          1,
          jiaozhao.name,
          "#ty_ex__jiaozhao-choice:"..player.id.."::"..Fk:getCardById(id):toLogString()
        )[1]
        room:sendLog{
          type = "#Choice",
          from = player.id,
          arg = choice,
          toast = true,
        }
        room:addTableMark(player, "ty_ex__jiaozhao_types-phase", Fk:cloneCard(choice):getTypeString()[1])
        room:setCardMark(Fk:getCardById(id), "@ty_ex__jiaozhao-inhand-turn", Fk:translate(choice))
        room:setCardMark(Fk:getCardById(id), "ty_ex__jiaozhao-inhand-turn", choice)
      end
    end
  end,
})
jiaozhao:addEffect("prohibit", {
  is_prohibited = function (self, from, to, card)
    return card and table.contains(card.skillNames, jiaozhao.name) and from:getMark("ty_ex__danxin") < 2 and from == to
  end,
})

return jiaozhao
