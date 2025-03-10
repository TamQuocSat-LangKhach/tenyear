local gongqiao = fk.CreateSkill { name = "gongqiao" }

Fk:loadTranslationTable {
  ['gongqiao'] = '工巧',
  ['#gongqiao-active'] = '发动 工巧，将一张手牌置入你的装备区',
  ['gongqiao_prohibit'] = '没有可用装备栏',
  ['#gongqiao_trigger'] = '工巧',
  ['#gongqiao_trigger2'] = '工巧',
  [':gongqiao'] = '出牌阶段限一次，你可以将一张手牌置入你的装备区（替换原装备，离开你的装备区时移出游戏）。若你的装备区里有以此法置入的：基本牌，你使用基本牌的数值+1；锦囊牌，你每回合首次使用一种类别的牌后摸一张牌；装备牌，你的手牌上限+3。',
  ['$gongqiao1'] = '怀兼爱之心，琢世间百器。',
  ['$gongqiao2'] = '机巧用尽，方化腐朽为神奇！',
}

gongqiao:addEffect('active', {
  anim_type = "support",
  prompt = "#gongqiao-active",
  max_phase_use_time = 1,
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:getMark("gongqiao-phase") == 0
  end,
  interaction = function(self, player)
    local all_choices = {
      "WeaponSlot",
      "ArmorSlot",
      "DefensiveRideSlot",
      "OffensiveRideSlot",
      "TreasureSlot"
    }
    local subtypes = {
      Card.SubtypeWeapon,
      Card.SubtypeArmor,
      Card.SubtypeDefensiveRide,
      Card.SubtypeOffensiveRide,
      Card.SubtypeTreasure
    }
    local choices = {}
    for i = 1, 5, 1 do
      if #player:getAvailableEquipSlots(subtypes[i]) > 0 then
        table.insert(choices, all_choices[i])
      end
    end
    if #choices == 0 then
      return UI.ComboBox { choices = { "gongqiao_prohibit" } }
    else
      return UI.ComboBox { choices = choices, all_choices = all_choices }
    end
  end,
  card_filter = function(self, player, to_select, selected)
    return skill.interaction.data ~= "gongqiao_prohibit" and
      #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:addPlayerMark(player, "gongqiao-phase", 1)
    room:moveCardTo(effect.cards, Card.Void, nil, fk.ReasonPut, gongqiao.name, "", true, player.id)
  end,

  on_lose = function(self, player)
    player.room:setPlayerMark(player, "gongqiao-phase", 0)
  end,
})

gongqiao:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return player.id == data.from and data.card.type == Card.TypeBasic and player:hasSkill(gongqiao.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + 1
    data.additionalRecover = (data.additionalRecover or 0) + 1
    if data.card.name == "analeptic" and not (data.extra_data and data.extra_data.analepticRecover) then
      data.extra_data = data.extra_data or {}
      data.extra_data.additionalDrank = (data.extra_data.additionalDrank or 0) + 1
    end
  end,
})

gongqiao:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if player.id ~= data.from or not player:hasSkill(gongqiao.name) then return false end
    local card_type = data.card.type
    local room = player.room
    local logic = room.logic
    local use_event = logic:getCurrentEvent()
    local mark_name = "gongqiao_" .. data.card:getTypeString() .. "-turn"
    local mark = player:getMark(mark_name)
    if mark == 0 then
      logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local last_use = e.data[1]
        if last_use.from == player.id and last_use.card.type == card_type then
          mark = e.id
          room:setPlayerMark(player, mark_name, mark)
          return true
        end
        return false
      end, Player.HistoryTurn)
    end
    return mark == use_event.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, gongqiao.name)
  end,
})

gongqiao:addEffect('maxcards', {
  correct_func = function(self, player)
    if player:hasSkill(gongqiao.name) then
      return 3
    else
      return 0
    end
  end,
})

return gongqiao
