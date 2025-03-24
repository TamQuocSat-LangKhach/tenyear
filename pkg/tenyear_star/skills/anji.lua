local anji = fk.CreateSkill {
  name = "anji",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["anji"] = "谙计",
  [":anji"] = "锁定技，当一名角色使用牌时，若此牌花色是本轮中使用次数最少的，你摸一张牌。",

  ["@anji-round"] = "谙计",

  ["$anji1"] = "兵法谙熟于胸，今乃施为之时。",
  ["$anji2"] = "我军待时而动，以有备击不备。",
}

local U = require "packages/utility/utility"

anji:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if player:hasSkill(anji.name) and data.card.suit ~= Card.NoSuit then
      local mark = player:getTableMark("anji-round")
      if #mark == 4 then
        return table.every(mark, function (y)
          return y >= mark[data.card.suit]
        end)
      end
    end
  end,
  on_use = function (self, event, target, player, data)
    player:drawCards(1, anji.name)
  end,

  can_refresh = function (self, event, target, player, data)
    return player:hasSkill(anji.name, true) and data.card.suit ~= Card.NoSuit
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("anji-round")
    if type(mark) ~= "table" then
      mark = {0, 0, 0, 0}
    end
    mark[data.card.suit] = mark[data.card.suit] + 1
    room:setPlayerMark(player, "anji-round", mark)
    local x, y = mark[1], 0
    local n = 1
    for i = 2, 4, 1 do
      y = mark[i]
      if y == x then
        n = 0
      elseif y < x then
        n = i
        x = y
      end
    end
    if n == 0 then
      room:setPlayerMark(player, "@anji-round", 0)
    else
      room:setPlayerMark(player, "@anji-round", U.ConvertSuit(n, "int", "sym"))
    end
  end,
})

return anji
