local posuo = fk.CreateSkill {
  name = "posuo"
}

Fk:loadTranslationTable{
  ['posuo'] = '婆娑',
  ['#posuo-viewas'] = '发动 婆娑，将一张手牌当此花色有的一张伤害牌来使用',
  ['@posuo-phase'] = '婆娑',
  ['posuo_name'] = '%arg [%arg2]',
  ['posuo_prohibit'] = '失效',
  [':posuo'] = '出牌阶段每种花色限一次，若你本阶段未对其他角色造成过伤害，你可以将一张手牌当此花色有的一张伤害牌使用。',
  ['$posuo1'] = '绯纱婆娑起，佳人笑靥红。',
  ['$posuo2'] = '红烛映俏影，一舞影斑斓。',
}

-- ViewAsSkill
posuo:addEffect('viewas', {
  prompt = "#posuo-viewas",
  interaction = function(player)
    local mark = player:getTableMark("@posuo-phase")
    local names = player:getMark("posuo_names")
    if type(names) ~= "table" then
      names = {}
      for _, id in ipairs(Fk:getAllCardIds()) do
        local card = Fk:getCardById(id, true)
        if card.is_damage_card and not card.is_derived then
          names[card.name] = names[card.name] or {}
          table.insertIfNeed(names[card.name], card:getSuitString(true))
        end
      end
      player:setMark("posuo_names", names)
    end

    local choices, all_choices = {}, {}
    for name, suits in pairs(names) do
      local _suits = {}
      for _, suit in ipairs(suits) do
        if not table.contains(mark, suit) then
          table.insert(_suits, U.ConvertSuit(suit, "sym", "icon"))
        end
      end
      local posuo_name = "posuo_name:::" .. name.. ":" .. table.concat(_suits, "")
      table.insert(all_choices, posuo_name)
      if #_suits > 0 then
        local to_use = Fk:cloneCard(name)
        if player:canUse(to_use) and not player:prohibitUse(to_use) then
          table.insert(choices, posuo_name)
        end
      end
    end

    if #choices == 0 then return false end
    return UI.ComboBox { choices = choices, all_choices = all_choices }
  end,
  enabled_at_play = function(self, player)
    local mark = player:getMark("@posuo-phase")
    return mark ~= "posuo_prohibit" and mark == 0 or (#mark < 4)
  end,
  card_filter = function(self, player, to_select, selected)
    if skill.interaction.data == nil or #selected > 0 or
      Fk:currentRoom():getCardArea(to_select) == Player.Equip then return false end
    local card = Fk:getCardById(to_select)
    local posuo_name = string.split(skill.interaction.data, ":")
    return string.find(posuo_name[#posuo_name], U.ConvertSuit(card.suit, "int", "icon"))
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not skill.interaction.data then return nil end
    local posuo_name = string.split(skill.interaction.data, ":")
    local card = Fk:cloneCard(posuo_name[4])
    card:addSubcard(cards[1])
    card.skillName = posuo.name
    return card
  end,
  before_use = function(self, player, use)
    local mark = player:getTableMark("@posuo-phase")
    table.insert(mark, use.card:getSuitString(true))
    player.room:setPlayerMark(player, "@posuo-phase", mark)
  end,
})

-- TriggerSkill for refresh
posuo:addEffect(fk.EventAcquireSkill, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(posuo.name, true) or player.phase ~= Player.Play or
      player:getMark("@posuo-phase") == "posuo_prohibit" then return false end
    return data == posuo and player == target
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    room.logic:getActualDamageEvents(1, function (e)
      local damage = e.data[1]
      if damage.from == player then
        room:setPlayerMark(player, "@posuo-phase", "posuo_prohibit")
        return true
      end
    end, Player.HistoryPhase)
  end,
})

posuo:addEffect(fk.HpChanged, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(posuo.name, true) or player.phase ~= Player.Play or
      player:getMark("@posuo-phase") == "posuo_prohibit" then return false end
    return data.damageEvent and data.damageEvent.from == player
  end,
  on_trigger = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@posuo-phase", "posuo_prohibit")
  end,
})

return posuo
