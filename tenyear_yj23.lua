local extension = Package("tenyear_yj23")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_yj23"] = "十周年-一将2023",
}

--夏侯楙 孙礼 陈式 费曜
local sunli = General(extension, "sunli", "wei", 4)
local kangli = fk.CreateTriggerSkill{
  name = "kangli",
  anim_type = "masochism",
  events = {fk.Damage, fk.Damaged, fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player then
      if event == fk.DamageCaused then
        return table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@kangli-inhand") > 0 end)
      else
        return player:hasSkill(self)
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if event == fk.DamageCaused then
      local ids = table.filter(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("@@kangli-inhand") > 0 end)
      room:throwCard(ids, self.name, player, player)
    else
      local cards = player:drawCards(2, self.name)
      cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player end)
      if #cards > 0 then
        for _, id in ipairs(cards) do
          room:setCardMark(Fk:getCardById(id), "@@kangli-inhand", 1)
        end
      end
    end
  end,
}
sunli:addSkill(kangli)
Fk:loadTranslationTable{
  ["sunli"] = "孙礼",
  ["kangli"] = "伉厉",
  [":kangli"] = "当你造成或受到伤害后，你摸两张牌，然后你下次造成伤害时弃置这些牌。",
  ["@@kangli-inhand"] = "伉厉",
}

local chenshi = General(extension, "chenshi", "shu", 4)
local qingbei = fk.CreateTriggerSkill{
  name = "qingbei",
  anim_type = "drawcard",
  events = {fk.RoundStart, fk.CardUseFinished},
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.RoundStart then
        return true
      elseif event == fk.CardUseFinished then
        if target == player and player:getMark("@qingbei-round") ~= 0 then
          local cardlist = data.card:isVirtual() and data.card.subcards or {data.card.id}
          if #cardlist == 0 then return end
          local yes = false
          local use_event = player.room.logic:getCurrentEvent()
          use_event:searchEvents(GameEvent.MoveCards, 1, function(e)
            if e.parent and e.parent.id == use_event.id then
              for _, move in ipairs(e.data) do
                if move.moveReason == fk.ReasonUse then
                  if move.from and move.from == player.id and
                    table.every(move.moveInfo, function(info) return info.fromArea == Card.PlayerHand end) then
                    yes = true
                  end
                end
              end
            end
          end)
          return yes
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    if event == fk.RoundStart then
      local room = player.room
      local suits = {"log_spade", "log_heart", "log_club", "log_diamond"}  --妖梦佬救救QwQ
      local choices = {"Cancel"}
      table.insertTable(choices, table.map(suits, function(s) return Fk:translate(s) end))
      local all_choices = table.simpleClone(choices)
      local result = {}
      while true do
        local choice = room:askForChoice(player, choices, self.name, "#qingbei-choice", false, all_choices)
        if choice == "Cancel" then
          break
        else
          table.removeOne(choices, choice)
          table.insert(result, suits[table.indexOf(all_choices, choice) - 1])
        end
      end
      if #result > 0 then
        self.cost_data = result
        return true
      end
    else
      return true
    end
  end,
  on_use = function (self, event, target, player, data)
    if event == fk.RoundStart then
      player.room:setPlayerMark(player, "@qingbei-round", self.cost_data)
    else
      player:drawCards(#player:getMark("@qingbei-round"), self.name)
    end
  end,
}
local qingbei_prohibit = fk.CreateProhibitSkill{
  name = "#qingbei_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@qingbei-round") ~= 0 and table.contains(player:getMark("@qingbei-round"), card:getSuitString(true))
  end,
}
qingbei:addRelatedSkill(qingbei_prohibit)
chenshi:addSkill(qingbei)
Fk:loadTranslationTable{
  ["chenshi"] = "陈式",
  ["qingbei"] = "擎北",
  [":qingbei"] = "每轮开始时，你可以选择任意种花色令你本轮无法使用，然后本轮你使用一张手牌后，摸本轮〖擎北〗选择过的花色数的牌。",
  ["#qingbei-choice"] = "擎北：选择你本轮不能使用的花色",
  ["@qingbei-round"] = "擎北",

  ["$qingbei1"] = "待追上那司马懿，定教他没好果子吃！",
  ["$qingbei2"] = "身若不周，吾一人可作擎北之柱。",
  ["~chenshi"] = "丞相、丞相！是魏延指使我的！",
}

return extension
