local panshi = fk.CreateSkill {
  name = "panshi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["panshi"] = "叛弑",
  [":panshi"] = "锁定技，准备阶段，你将一张手牌交给拥有技能〖慈孝〗的角色；你于出牌阶段使用【杀】对其造成伤害时，此伤害+1，"..
  "且此伤害结算后结束出牌阶段。",

  ["#panshi-give-to"] = "叛弑：你需将一张手牌交给%src",
  ["#panshi-give"] = "叛弑：你需将一张手牌交给拥有〖慈孝〗的角色",
}

panshi:addEffect(fk.EventPhaseStart, {
  anim_type = "negative",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(panshi.name) and player.phase == Player.Start and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return p:hasSkill("cixiao", true)
      end)
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local fathers = table.filter(room:getOtherPlayers(player, false), function (p)
      return p:hasSkill("cixiao", true)
    end)
    if #fathers == 1 then
      room:doIndicate(player, fathers)
      if player:isKongcheng() then return false end
      local card = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        prompt = "#panshi-give-to:"..fathers[1].id,
        skill_name = panshi.name,
        cancelable = false,
      })
      room:obtainCard(fathers[1], card, false, fk.ReasonGive, player, panshi.name)
    else
      if player:isKongcheng() then return end
      local to, card = room:askToChooseCardsAndPlayers(player, {
        min_card_num = 1,
        max_card_num = 1,
        min_num = 1,
        max_num = 1,
        targets = fathers,
        pattern = ".|.|.|hand",
        skill_name = panshi.name,
        prompt = "#panshi-give",
        cancelable = false,
      })
      room:obtainCard(to[1], card, false, fk.ReasonGive, player, panshi.name)
    end
  end,
})

panshi:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(panshi.name) and player.phase == Player.Play and
      data.card and data.card.trueName =="slash" and data.to:hasSkill("cixiao", true) and player.room.logic:damageByCardEffect()
  end,
  on_use = function (self, event, target, player, data)
    data:changeDamage(1)
    data.extra_data = data.extra_data or {}
    data.extra_data.panshi = player
  end,
})

panshi:addEffect(fk.Damage, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player.phase == Player.Play and data.extra_data and data.extra_data.panshi == player
  end,
  on_refresh = function (self, event, target, player, data)
    player:endPlayPhase()
  end,
})

panshi:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@@panshi_son", 0)
end)

return panshi
