local taoluan = fk.CreateSkill {
  name = "ty__taoluan"
}

Fk:loadTranslationTable{
  ['ty__taoluan'] = '滔乱',
  ['#ty__taoluan-prompt'] = '滔乱：每牌名限一次，你可将一张牌当任意一张基本牌或普通锦囊牌使用',
  ['@[ty__taoluan]'] = '滔乱',
  ['#ty__taoluan-choose'] = '滔乱：令一名其他角色交给你一张非%arg，或你失去1点体力且本回合〖滔乱〗失效',
  ['#ty__taoluan-card'] = '滔乱：你需交给 %src 一张非%arg，否则其失去1点体力且本回合〖滔乱〗失效',
  ['$ty__taoluan1'] = '汉室动荡？莫来妖言惑众。',
  ['$ty__taoluan2'] = '自打洒家进宫以来，就独得皇上恩宠。',
}

taoluan:addEffect('viewas', {
  pattern = ".",
  prompt = "#ty__taoluan-prompt",
  interaction = function()
    local all_names = U.getAllCardNames("bt")
    return U.CardNameBox {
      choices = U.getViewAsCardNames(Self, "ty__taoluan", all_names, nil, Self:getTableMark("@[ty__taoluan]").value),
      all_choices = all_names,
      default_choice = "AskForCardsChosen",
    }
  end,
  card_filter = function(self, player, to_select, selected)
    if Fk.all_card_types[self.interaction.data] == nil then return false end
    if #selected > 0 then return false end
    local card = Fk:getCardById(to_select)
    if card.suit == Card.NoSuit then return false end
    local mark = player:getMark("@[ty__taoluan]")
    return type(mark) ~= "table" or not table.contains(mark.suits, card.suit)
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
        loseHp = false
      }
    end
    table.insert(mark.value, use.card.trueName)
    table.insert(mark.suits, use.card.suit)
    player.room:setPlayerMark(player, "@[ty__taoluan]", mark)
  end,
  after_use = function(self, player, use)
    local room = player.room
    if player.dead or #room.alive_players < 2 then return end
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local type = use.card:getTypeString()
    local tos = room:askToChoosePlayers(player, {
      targets = U.toServerPlayerArray(targets),
      min_num = 1,
      max_num = 1,
      prompt = "#ty__taoluan-choose:::"..type,
      skill_name = taoluan.name
    })
    local to = room:getPlayerById(tos[1])
    local card = room:askToCards(to, {
      min_num = 1,
      max_num = 1,
      pattern = ".|.|.|.|.|^"..type,
      prompt = "#ty__taoluan-card:"..player.id.."::"..type
    })
    if #card > 0 then
      room:obtainCard(player, card[1], false, fk.ReasonGive, to.id)
    elseif player:hasSkill(taoluan, true) then
      room:invalidateSkill(player, "ty__taoluan", "-turn")
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
    local mark = player:getMark("@[ty__taoluan]")
    return not response and type(mark) ~= "table" or
      (#mark.suits < 4 and #U.getViewAsCardNames(player, "ty__taoluan", U.getAllCardNames("bt"), nil, mark.value) > 0)
  end,
  on_lose = function(self, player)
    player.room:setPlayerMark(player, "@[ty__taoluan]", 0)
  end,
})

taoluan:addEffect(fk.TurnEnd, {
  anim_type = "negative",
  main_skill = taoluan,
  can_trigger = function(self, event, target, player, data)
    local mark = player:getMark("@[ty__taoluan]")
    return type(mark) == "table" and mark.loseHp
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:loseHp(player, 1, taoluan.name)
  end,

  can_refresh = function(self, event, target, player, data)
    local mark = player:getMark("@[ty__taoluan]")
    return type(mark) == "table" and (#mark.suits > 0 or mark.loseHp)
  end,
  on_refresh = function(self, event, target, player, data)
    local mark = player:getMark("@[ty__taoluan]")
    mark.suits = {}
    mark.loseHp = false
    player.room:setPlayerMark(player, "@[ty__taoluan]", mark)
  end,
})

return taoluan
