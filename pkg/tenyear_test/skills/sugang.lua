local sugang = fk.CreateSkill {
  name = "sugang",
}

Fk:loadTranslationTable{
  ["sugang"] = "肃纲",
  [":sugang"] = "出牌阶段开始时，你可以进行判定并获得生效后的判定牌，然后你选择至多两项：<br>"..
  "1.本回合你可以将此牌当任意伤害牌使用；<br>"..
  "2.展示一张手牌，本回合所有角色只能使用点数介于判定结果和展示牌之间的手牌；<br>"..
  "3.本回合你获得〖行殇〗且〖典论〗的“等量”改为“两倍”。",

  ["#sugang"] = "肃纲：你可以将“肃纲”牌当任意伤害牌使用",
  ["sugang1"] = "本回合可以将%arg当任意伤害牌使用",
  ["sugang2"] = "展示一张手牌，本回合所有角色只能使用点数介于%arg和展示牌之间的手牌",
  ["sugang3"] = "本回合你获得“行殇”且“典论”的等量改为两倍",
  ["#sugang-choice"] = "肃纲：选择至多两项",
  ["@@sugang-inhand-turn"] = "肃纲",
  ["#sugang-show"] = "肃纲：请展示一张手牌，本回合所有角色只能使用点数介于%arg和展示牌之间的手牌",
  ["@sugang-turn"] = "肃纲",

  ["$sugang1"] = "",
  ["$sugang2"] = "",
}

local U = require "packages/utility/utility"

sugang:addEffect("viewas", {
  anim_type = "offensive",
  prompt = "#sugang",
  interaction = function(self, player)
    local all_names = player:getTableMark(sugang.name)
    local names = player:getViewAsCardNames(sugang.name, all_names)
    if #names == 0 then return end
    return U.CardNameBox { choices = names, all_choices = all_names }
  end,
  card_filter = function (self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):getMark("@@sugang-inhand-turn") > 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or Fk.all_card_types[self.interaction.data] == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = sugang.name
    return card
  end,
  enabled_at_play = function(self, player)
    return table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@sugang-inhand-turn") > 0
    end)
  end,
  enabled_at_response = function (self, player, response)
    if response then return end
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@sugang-inhand-turn") > 0
    end)
    return #cards > 0 and
      table.find(cards, function (id)
        return #player:getViewAsCardNames(sugang.name, player:getTableMark(sugang.name), {id}) > 0
      end)
  end,
})

sugang:addAcquireEffect(function (self, player, is_start)
  local room = player.room
  local names = {}
  for _, name in ipairs(Fk:getAllCardNames("bt")) do
    if Fk:cloneCard(name).is_damage_card then
      table.insert(names, name)
    end
  end
  room:setPlayerMark(player, sugang.name, names)
end)

sugang:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(sugang.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = sugang.name,
      pattern = ".",
    }
    room:judge(judge)
    if player.dead then return end
    local card = judge.card and Fk:getCardById(judge.card.id, true) or nil
    local all_choices, choices = {}, {}
    if card then
      table.insert(all_choices, "sugang1:::"..card:toLogString())
      table.insert(all_choices, "sugang2:::"..judge.card.number)
      if table.contains(player:getCardIds("h"), card.id) then
        table.insert(choices, "sugang1:::"..card:toLogString())
      end
    end
    if not player:isKongcheng() then
      table.insert(choices, "sugang2:::"..judge.card.number)
    end
    table.insert(all_choices, "sugang3")
    table.insert(choices, "sugang3")
    local choice = room:askToChoices(player, {
      choices = choices,
      min_num = 1,
      max_num = 2,
      skill_name = sugang.name,
      prompt = "#sugang-choice",
      cancelable = true,
    })
    if #choice == 0 then return end
    if table.find(choice, function (c)
      return c:startsWith("sugang1")
    end) then
      room:setCardMark(card, "@@sugang-inhand-turn", 1)
    end
    if table.find(choice, function (c)
      return c:startsWith("sugang2")
    end) then
      local id = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = sugang.name,
        prompt = "#sugang-show:::"..judge.card.number,
        cancelable = false,
      })[1]
      local number1, number2 = judge.card.number, Fk:getCardById(id).number
      if number1 > number2 then
        number1, number2 = number2, number1
      end
      player:showCards(id)
      if not player.dead then
        if player:getMark("sugang-turn") ~= 0 then
          number1 = math.min(number1, player:getMark("sugang-turn")[1])
          number2 = math.max(number2, player:getMark("sugang-turn")[2])
        end
        room:setPlayerMark(player, "sugang-turn", {number1, number2})
        room:setPlayerMark(player, "@sugang-turn", number1..", "..number2)
      end
    end
    if table.contains(choice, "sugang3") then
      room:setPlayerMark(player, "dianlun_update-turn", 1)
      if not player:hasSkill("xingshang") then
        room:handleAddLoseSkills(player, "xingshang")
        room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
          room:handleAddLoseSkills(player, "-xingshang")
        end)
      end
    end
  end,
})

sugang:addEffect(fk.FinishJudge, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.reason == sugang.name and player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.card, true, nil, player, sugang.name)
  end,
})

sugang:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if card then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      if #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds("h"), id)
      end) then
        for _, p in ipairs(Fk:currentRoom().alive_players) do
          if p:getMark("sugang-turn") ~= 0 then
            for _, id in ipairs(subcards) do
              if Fk:getCardById(id).number < p:getMark("sugang-turn")[1] or Fk:getCardById(id).number > p:getMark("sugang-turn")[2] then
                return true
              end
            end
          end
        end
      end
    end
  end,
})

return sugang
