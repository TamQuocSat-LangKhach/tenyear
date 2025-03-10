local ty__weipo = fk.CreateSkill {
  name = "ty__weipo"
}

Fk:loadTranslationTable{
  ['ty__weipo'] = '危迫',
  ['#ty__weipo_delay'] = '危迫',
  ['#ty__weipo-give'] = '危迫：必须选择一张手牌交给%src，且本回合危迫失效',
  [':ty__weipo'] = '锁定技，当你成为其他角色使用【杀】或普通锦囊牌的目标后，你将手牌摸至X张，然后若你因此摸牌且此牌结算结束后你的手牌数小于X，你交给该角色一张手牌且此技能失效直到你的下回合开始。（X为你的体力上限）',
  ['$ty__weipo1'] = '临渊勒马，进退维谷！',
  ['$ty__weipo2'] = '前狼后虎，朝不保夕！',
}

ty__weipo:addEffect(fk.TargetConfirmed, {
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(ty__weipo) and player == target and data.from ~= player.id and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and player:getHandcardNum() < player.maxHp
  end,
  on_use = function(self, event, target, player, data)
    if player:getHandcardNum() < player.maxHp then
      player:drawCards(player.maxHp - player:getHandcardNum(), ty__weipo.name)
      data.extra_data = data.extra_data or {}
      local weipo_players = data.extra_data.ty__weipo_players or {}
      table.insertIfNeed(weipo_players, player.id)
      data.extra_data.ty__weipo_players = weipo_players
    end
  end,
  can_refresh = function (self, event, target, player, data)
    if event == fk.EventLoseSkill and data ~= ty__weipo then return false end
    return target == player and player:getMark("ty__weipo_invalidity") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "ty__weipo_invalidity", 0)
    room:validateSkill(player, ty__weipo.name)
  end,
})

ty__weipo:addEffect(fk.CardUseFinished, {
  name = "#ty__weipo_delay",
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.ty__weipo_players and table.contains(data.extra_data.ty__weipo_players, player.id) and
      not player.dead and player:getHandcardNum() < player.maxHp
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, ty__weipo.name, "negative")
    player:broadcastSkillInvoke(ty__weipo.name)
    if not target.dead and not player:isKongcheng() then
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        pattern = ".",
        prompt = "#ty__weipo-give:"..target.id,
        skill_name = ty__weipo.name
      })
      if #card > 0 then
        room:obtainCard(target.id, card[1], false, fk.ReasonGive)
      end
    end
    if player:hasSkill(ty__weipo, true) and player:getMark("ty__weipo_invalidity") == 0 then
      room:invalidateSkill(player, ty__weipo.name)
    end
  end,
})

return ty__weipo
