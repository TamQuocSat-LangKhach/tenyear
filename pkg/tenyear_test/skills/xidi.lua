local xidi = fk.CreateSkill {
  name = "xidi",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xidi"] = "羲笛",
  [":xidi"] = "锁定技，游戏开始时，你的初始手牌增加“笛”标记且不计入手牌上限。准备阶段和结束阶段，你观看牌堆顶的X张牌"..
  "（X为你的“笛”数，至少为1至多为8），以任意顺序置于牌堆顶或牌堆底。",

  ["@@xidi-inhand"] = "笛",

  ["$xidi1"] = "",
  ["$xidi2"] = "",
}

xidi:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xidi.name) and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getCardIds("h")) do
      room:setCardMark(Fk:getCardById(id), "@@xidi-inhand", 1)
    end
  end,
})

xidi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xidi.name) and (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@xidi-inhand") > 0
    end)
    n = math.min(n, 8)
    n = math.max(n, 1)
    room:askToGuanxing(player, {
      cards = room:getNCards(n),
      skill_name = xidi.name,
    })
  end,
})

xidi:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card:getMark("@@xidi-inhand") > 0
  end,
})

xidi:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, id in ipairs(player:getCardIds("h")) do
    room:setCardMark(Fk:getCardById(id), "@@xidi-inhand", 0)
  end
end)

return xidi
