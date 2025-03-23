local wuniang = fk.CreateSkill {
  name = "ty__wuniang",
}

Fk:loadTranslationTable{
  ["ty__wuniang"] = "武娘",
  [":ty__wuniang"] = "当你使用或打出【杀】时，你可以获得一名其他角色的一张牌，若如此做，其摸一张牌。若你已发动〖许身〗，则关索也摸一张牌。",

  ["#ty__wuniang1-choose"] = "武娘：你可以获得一名角色的一张牌，其摸一张牌",
  ["#ty__wuniang2-choose"] = "武娘：你可以获得一名角色的一张牌，其摸一张牌，关索摸一张牌",

  ["$ty__wuniang1"] = "得公亲传，彰其武威。",
  ["$ty__wuniang2"] = "灵彩武动，娇影摇曳。",
}

local spec = {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(wuniang.name) and data.card.trueName == "slash" and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt = "#ty__wuniang1-choose"
    if player:usedSkillTimes("ty__xushen", Player.HistoryGame) > 0 and
      table.find(room.alive_players, function(p)
        return string.find(p.general, "guansuo") ~= nil or string.find(p.deputyGeneral, "guansuo") ~= nil
      end) then
      prompt = "#ty__wuniang2-choose"
    end
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = prompt,
      skill_name = wuniang.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = wuniang.name,
    })
    room:obtainCard(player, id, false, fk.ReasonPrey, player, wuniang.name)
    if not to.dead then
      to:drawCards(1, wuniang.name)
    end
    if player:usedSkillTimes("ty__xushen", Player.HistoryGame) > 0 then
      for _, p in ipairs(room:getAlivePlayers()) do
        if (string.find(p.general, "guansuo") or string.find(p.deputyGeneral, "guansuo")) and not p.dead then
          p:drawCards(1, wuniang.name)
        end
      end
    end
  end,
}

wuniang:addEffect(fk.CardUsing, spec)
wuniang:addEffect(fk.CardResponding, spec)

return wuniang
