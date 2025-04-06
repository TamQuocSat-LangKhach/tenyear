local taoluan = fk.CreateSkill {
  name = "ty__taoluan",
}

Fk:loadTranslationTable{
  ["ty__taoluan"] = "滔乱",
  [":ty__taoluan"] = "每种牌名限一次、每回合每种花色限一次，你可以将一张牌当任意基本牌或普通锦囊牌使用，"..
  "然后令一名其他角色选择：1.交给你一张类别不同的牌；2.本回合此技能失效，且此回合结束时你失去1点体力。",

  ["#ty__taoluan"] = "滔乱：将一张牌当任意基本牌或普通锦囊牌使用",
  ["@[ty__taoluan]"] = "滔乱",
  ["#ty__taoluan-choose"] = "滔乱：选择一名角色，其交给你一张非%arg或令你失去1点体力且本回合“滔乱”失效",
  ["#ty__taoluan-card"] = "滔乱：交给 %src 一张非%arg，否则其失去1点体力且本回合“滔乱”失效",

  ["$ty__taoluan1"] = "汉室动荡？莫来妖言惑众。",
  ["$ty__taoluan2"] = "自打洒家进宫以来，就独得皇上恩宠。",
}

local U = require "packages/utility/utility"

Fk:addQmlMark{
  name = "ty__taoluan",
  how_to_show = function(_, value)
    if type(value) ~= "table" then return " " end
    if value.loseHp then return Fk:translate("lose_hp") end
    if type(value.suits) ~= "table" or #value.suits == 0 then return " " end
    return table.concat(table.map(value.suits, function(s)
      return Fk:translate(s)
    end), "")
  end,
  qml_path = "packages/utility/qml/ViewPile"
}

taoluan:addEffect("viewas", {
  pattern = ".",
  prompt = "#ty__taoluan",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("bt")
    local names = player:getViewAsCardNames(taoluan.name, all_names, nil, player:getTableMark("@[ty__taoluan]").value)
    if #names == 0 then return end
    return U.CardNameBox {choices = names, all_choices = all_names}
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and Fk.all_card_types[self.interaction.data] then
      local card = Fk:getCardById(to_select)
      if card.suit == Card.NoSuit then return false end
      local mark = player:getMark("@[ty__taoluan]")
      return type(mark) ~= "table" or not table.contains(mark.suits, card:getSuitString(true))
    end
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or Fk.all_card_types[self.interaction.data] == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = taoluan.name
    return card
  end,
  before_use = function(self, player, use)
    local mark = player:getMark("@[ty__taoluan]")
    if type(mark) ~= "table" then
      mark = {
        value = {},
        suits = {},
        loseHp = false,
      }
    end
    table.insert(mark.value, use.card.trueName)
    table.insert(mark.suits, use.card:getSuitString(true))
    player.room:setPlayerMark(player, "@[ty__taoluan]", mark)
  end,
  after_use = function(self, player, use)
    local room = player.room
    if player.dead or #room:getOtherPlayers(player, false) == 0 then return end
    local type = use.card:getTypeString()
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#ty__taoluan-choose:::"..type,
      skill_name = taoluan.name,
      cancelable = false,
    })[1]
    local card = room:askToCards(to, {
      skill_name = taoluan.name,
      min_num = 1,
      max_num = 1,
      pattern = ".|.|.|.|.|^"..type,
      prompt = "#ty__taoluan-card:"..player.id.."::"..type,
    })
    if #card > 0 then
      room:obtainCard(player, card, false, fk.ReasonGive, to.id, taoluan.name)
    elseif player:hasSkill(taoluan.name, true) then
      room:invalidateSkill(player, taoluan.name, "-turn")
      local mark = player:getTableMark("@[ty__taoluan]")
      mark.loseHp = true
      room:setPlayerMark(player, "@[ty__taoluan]", mark)
    end
  end,
  enabled_at_play = function(self, player)
    local mark = player:getMark("@[ty__taoluan]")
    return type(mark) ~= "table" or #mark.suits < 4
  end,
  enabled_at_response = function(self, player, response)
    if response then return end
    local mark = player:getMark("@[ty__taoluan]")
    return type(mark) ~= "table" or
      (#mark.suits < 4 and #player:getViewAsCardNames(taoluan.name, Fk:getAllCardNames("bt"), nil, mark.value) > 0)
  end,
})

taoluan:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@[ty__taoluan]", 0)
end)

taoluan:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    local mark = player:getMark("@[ty__taoluan]")
    return type(mark) == "table" and mark.loseHp
  end,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, taoluan.name)
  end,

  late_refresh = true,
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@[ty__taoluan]") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark("@[ty__taoluan]")
    mark.suits = {}
    mark.loseHp = false
    player.room:setPlayerMark(player, "@[ty__taoluan]", mark)
  end,
})

return taoluan
