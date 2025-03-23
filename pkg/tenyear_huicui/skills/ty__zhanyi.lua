local ty__zhanyi = fk.CreateSkill {
  name = "ty__zhanyi"
}

Fk:loadTranslationTable{
  ['ty__zhanyi'] = '战意',
  ['#ty__zhanyi-choice'] = '是否发动 战意，弃置一种类别所有的牌，另两张类别的牌获得额外效果',
  ['@[cardtypes]ty__zhanyi'] = '战意',
  ['#ty__zhanyi-discard'] = '战意：你可以弃置一名角色一张牌',
  [':ty__zhanyi'] = '出牌阶段开始时，你可以弃置一种类别的所有牌，另外两种类别的牌获得以下效果直到你的下个回合开始：<br>基本牌，你使用基本牌无距离限制且造成的伤害和回复值+1；<br>锦囊牌，你使用锦囊牌时摸一张牌，你的锦囊牌不计入手牌上限；<br>装备牌，当装备牌置入你的装备区后，可以弃置一名其他角色的一张牌。',
  ['$ty__zhanyi1'] = '此命不已，此战不休！',
  ['$ty__zhanyi2'] = '以役兴国，战意磅礴！',
}

ty__zhanyi:addEffect(fk.EventPhaseStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__zhanyi) and player.phase == Player.Play and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local all_choices = {"basic", "trick", "equip", "Cancel"}
    local choices = {"Cancel"}
    for _, id in ipairs(player:getCardIds("he")) do
      local card = Fk:getCardById(id)
      --if not player:prohibitDiscard(card) then
      table.insertIfNeed(choices, card:getTypeString())
      --end
    end
    if #choices == 1 then return end
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = ty__zhanyi.name,
      prompt = "#ty__zhanyi-choice",
      detailed = false,
      all_choices = all_choices
    })
    if choice ~= "Cancel" then
      event:setCostData(skill, choice)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local types = {"basic", "trick", "equip"}
    local card_type = event:getCostData(skill)
    local mark = player:getTableMark("@[cardtypes]ty__zhanyi")
    if card_type == "basic" then
      table.insertTableIfNeed(mark, {2, 3})
    elseif card_type == "trick" then
      table.insertTableIfNeed(mark, {1, 3})
    elseif card_type == "equip" then
      table.insertTableIfNeed(mark, {1, 2})
    end
    room:setPlayerMark(player, "@[cardtypes]ty__zhanyi", mark)
    local cards = table.filter(player:getCardIds("he"), function(id)
      local card = Fk:getCardById(id)
      return card:getTypeString() == card_type and not player:prohibitDiscard(card)
    end)
    if #cards > 0 then
      room:throwCard(cards, ty__zhanyi.name, player, player)
    end
  end,
})

ty__zhanyi:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@[cardtypes]ty__zhanyi") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@[cardtypes]ty__zhanyi", 0)
  end,
})

ty__zhanyi:addEffect(fk.CardUsing, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and
      player:getCardTypeString(target:getTableMark("@[cardtypes]ty__zhanyi")) < 3 and table.contains(player:getTableMark("@[cardtypes]ty__zhanyi"), target:getTableMark("@[cardtypes]ty__zhanyi"))
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ty__zhanyi")
    if event == fk.CardUsing then
      if data.card.type == Card.TypeBasic then
        if data.card.is_damage_card then
          room:notifySkillInvoked(player, "ty__zhanyi", "offensive")
          data.additionalDamage = (data.additionalDamage or 0) + 1
        elseif data.card.name == "peach" then
          room:notifySkillInvoked(player, "ty__zhanyi", "support")
          data.additionalRecover = (data.additionalRecover or 0) + 1
        elseif data.card.name == "analeptic" and data.extra_data and data.extra_data.analepticRecover then
          room:notifySkillInvoked(player, "ty__zhanyi", "support")
          data.additionalRecover = (data.additionalRecover or 0) + 1
        else
          room:notifySkillInvoked(player, "ty__zhanyi", "special")
        end
      elseif data.card.type == Card.TypeTrick then
        room:notifySkillInvoked(player, "ty__zhanyi", "drawcard")
        player:drawCards(1, ty__zhanyi.name)
      end
    else
      room:notifySkillInvoked(player, "ty__zhanyi", "control")
      local targets = table.map(table.filter(room.alive_players, function(p)
        return p ~= player and not p:isNude() 
      end), Util.IdMapper)
      if #targets == 0 then return false end
      local to = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        skill_name = ty__zhanyi.name,
        prompt = "#ty__zhanyi-discard",
        cancelable = true
      })
      if #to > 0 then
        to = room:getPlayerById(to[1])
        local id = room:askToChooseCard(player, {
          target = to,
          flag = "he",
          skill_name = ty__zhanyi.name
        })
        room:throwCard({id}, ty__zhanyi.name, to, player)
      end
    end
  end,
})

ty__zhanyi:addEffect(fk.AfterCardsMove, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return table.contains(player:getTableMark("@[cardtypes]ty__zhanyi"), 3) and 
      table.any(data, function(move)
        return move.to and move.to == player.id and move.toArea == Player.Equip and #move.moveInfo > 0
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("ty__zhanyi")
    room:notifySkillInvoked(player, "ty__zhanyi", "control")
    local targets = table.map(table.filter(room.alive_players, function(p)
      return p ~= player and not p:isNude() 
    end), Util.IdMapper)
    if #targets == 0 then return false end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = ty__zhanyi.name,
      prompt = "#ty__zhanyi-discard",
      cancelable = true
    })
    if #to > 0 then
      to = room:getPlayerById(to[1])
      local id = room:askToChooseCard(player, {
        target = to,
        flag = "he",
        skill_name = ty__zhanyi.name
      })
      room:throwCard({id}, ty__zhanyi.name, to, player)
    end
  end,
})

ty__zhanyi:addEffect('targetmod', {
  bypass_distances = function(self, player, skill, card)
    return table.contains(player:getTableMark("@[cardtypes]ty__zhanyi"), 1) and card and card.type == Card.TypeBasic
  end,
})

ty__zhanyi:addEffect('maxcards', {
  exclude_from = function(self, player, card)
    return table.contains(player:getTableMark("@[cardtypes]ty__zhanyi"), 2) and card.type == Card.TypeTrick
  end,
})

return ty__zhanyi
