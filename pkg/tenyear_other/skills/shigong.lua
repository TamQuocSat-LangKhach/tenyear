local shigong = fk.CreateSkill {
  name = "shigong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["shigong"] = "世公",
  [":shigong"] = "锁定技，你的武将标记初始为“袁绍”。你每回合使用的第一张手牌不受〖烈悌〗限制，然后你切换标记为对应武将。"..
  "若因此切换为袁绍，你视为使用一张【万箭齐发】；若因此切换为袁术，你摸两张牌。",

  ["@shigong"] = "",
}

shigong:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(shigong.name) and
      data.extra_data and data.extra_data.shigong and data.extra_data.shigong ~= player:getMark("@shigong")
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local mark = data.extra_data.shigong
    room:setPlayerMark(player, "@shigong", mark)
    if mark == Fk:translate("yuanshu") then
      player:drawCards(2, shigong.name)
    elseif mark == Fk:translate("yuanshao") then
      local card = Fk:cloneCard("archery_attack")
      card.skillName = shigong.name
      local targets = table.filter(room:getOtherPlayers(player, false), function (p)
        return not player:isProhibited(p, card)
      end)
      if #targets > 0 then
        room:useVirtualCard("archery_attack", nil, player, targets, shigong.name)
      end
    end
  end,
})

shigong:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(shigong.name) and
      #Card:getIdList(data.card) > 0 and
      table.every(Card:getIdList(data.card), function (id)
        return table.contains(player:getCardIds("h"), id)
      end)
  end,
  on_refresh = function (self, event, target, player, data)
    player.room:setPlayerMark(player, "shigong-turn", 1)
    if data.card:getMark("@lieti-inhand") ~= 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.shigong = data.card:getMark("@lieti-inhand")
    end
  end,
})

shigong:addAcquireEffect(function (self, player, is_start)
  player.room:setPlayerMark(player, "@shigong", Fk:translate("yuanshao"))
end)

shigong:addLoseEffect(function (self, player, is_death)
  if not player:hasSkill("lieti", true) then
    player.room:setPlayerMark(player, "@shigong", 0)
  end
end)

return shigong
