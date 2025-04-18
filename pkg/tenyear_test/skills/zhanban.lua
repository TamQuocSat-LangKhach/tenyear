
local zhanban = fk.CreateSkill {
  name = "zhanban",
}

Fk:loadTranslationTable{
  ["zhanban"] = "斩绊",
  [":zhanban"] = "出牌阶段限一次，你可以令所有其他角色将手牌数调整至与你相同。若因此弃牌，其摸三张牌；若因此摸牌，其弃置三张牌；\
  若未摸牌或弃牌，你对其造成1点伤害。",

  ["#zhanban"] = "斩绊：令所有角色将手牌数调整至与你相同，根据是否弃牌或摸牌执行效果",

  ["$zhanban1"] = "",
  ["$zhanban2"] = "",
}

zhanban:addEffect("active", {
  anim_type = "control",
  prompt = "#zhanban",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(zhanban.name, Player.HistoryPhase) == 0 and
      #Fk:currentRoom().alive_players > 1
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = room:getOtherPlayers(player)
    if player:hasSkill("tiancheng") then
      local tos = table.filter(targets, function (p)
        return p.kingdom == "qun"
      end)
      tos = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 9,
        targets = tos,
        skill_name = "tiancheng",
        prompt = "#tiancheng-choose",
        cancelable = true,
      })
      if #tos > 0 then
        player:broadcastSkillInvoke("tiancheng")
        room:notifySkillInvoked(player, "tiancheng", "control")
        for _, p in ipairs(tos) do
          table.removeOne(targets, p)
        end
      end
    end
    if #targets == 0 then return end
    room:doIndicate(player, targets)
    local x, result = player:getHandcardNum(), {}
    for _, p in ipairs(targets) do
      if not p.dead then
        local n = p:getHandcardNum() - x
        if n > 0 then
          local cards = room:askToDiscard(p, {
            min_num = n,
            max_num = n,
            include_equip = false,
            skill_name = zhanban.name,
            cancelable = false,
          })
          result[p] = #cards
        elseif n < 0 then
          result[p] = -n
          p:drawCards(-n, zhanban.name)
        else
          result[p] = 0
        end
      end
    end
    for _, p in ipairs(targets) do
      if not p.dead then
        if result[p] > 0 then
          room:askToDiscard(p, {
            min_num = 3,
            max_num = 3,
            include_equip = true,
            skill_name = zhanban.name,
            cancelable = false,
          })
        elseif result[p] < 0 then
          p:drawCards(3, zhanban.name)
        else
          room:damage {
            from = player,
            to = p,
            damage = 1,
            skillName = zhanban.name,
          }
        end
      end
    end
  end,
})

return zhanban
