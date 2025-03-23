local yuyun = fk.CreateSkill {
  name = "yuyun",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["yuyun"] = "玉陨",
  [":yuyun"] = "锁定技，出牌阶段开始时，你失去1点体力或体力上限（你的体力上限不能以此法被减至1以下），然后选择X+1项（X为你已损失的体力值）：<br>"..
  "1.摸两张牌；<br>2.对一名其他角色造成1点伤害，然后本回合对其使用【杀】无距离和次数限制；<br>3.本回合没有手牌上限；<br>"..
  "4.获得一名其他角色区域内的一张牌；<br>5.令一名其他角色将手牌摸至体力上限（最多摸至5）。",

  ["yuyun2"] = "对一名角色造成1点伤害，本回合对其使用【杀】无距离次数限制",
  ["yuyun3"] = "本回合手牌上限无限",
  ["yuyun4"] = "获得一名其他角色区域内的一张牌",
  ["yuyun5"] = "令一名其他角色将手牌摸至体力上限（最多摸至5）",
  ["#yuyun2-choose"] = "玉陨：对一名角色造成1点伤害，本回合对其使用【杀】无距离和次数限制",
  ["@@yuyun-turn"] = "玉陨",
  ["#yuyun4-choose"] = "玉陨：获得一名角色区域内的一张牌",
  ["#yuyun5-choose"] = "玉陨：令一名角色将手牌摸至体力上限（最多摸至5）",

  ["$yuyun1"] = "春依旧，人消瘦。",
  ["$yuyun2"] = "泪沾青衫，玉殒香消。",
}

yuyun:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yuyun.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"loseHp"}
    if player.maxHp > 1 then
      table.insert(choices, "loseMaxHp")
    end
    local chc = room:askToChoice(player, {
      choices = choices,
      skill_name = yuyun.name
    })
    if chc == "loseMaxHp" then
      room:changeMaxHp(player, -1)
    else
      room:loseHp(player, 1, yuyun.name)
    end
    if player.dead then return end
    choices = {"draw2", "yuyun2", "yuyun3", "yuyun4", "yuyun5", "Cancel"}
    local n = 1 + player:getLostHp()
    for _ = 1, n do
      if player.dead or #choices < 2 then return end
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = yuyun.name,
      })
      if choice == "Cancel" then return end
      table.removeOne(choices, choice)
      if choice == "draw2" then
        player:drawCards(2, yuyun.name)
      elseif choice == "yuyun2" then
        if #room:getOtherPlayers(player, false) > 0 then
          local to = room:askToChoosePlayers(player, {
            targets = room:getOtherPlayers(player, false),
            min_num = 1,
            max_num = 1,
            prompt = "#yuyun2-choose",
            skill_name = yuyun.name,
          })
          if #to > 0 then
            room:damage{
              from = player,
              to = to[1],
              damage = 1,
              skillName = yuyun.name,
            }
            if not to[1].dead and not player.dead then
              room:setPlayerMark(to[1], "@@yuyun-turn", 1)
              room:addTableMarkIfNeed(player, "yuyun2-turn", to[1].id)
            end
          end
        end
      elseif choice == "yuyun3" then
        room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 999)
      elseif choice == "yuyun4" then
        local targets = table.filter(room:getOtherPlayers(player, false), function(p)
          return not p:isAllNude()
        end)
        if #targets > 0 then
          local to = room:askToChoosePlayers(player, {
            targets = targets,
            min_num = 1,
            max_num = 1,
            prompt = "#yuyun4-choose",
            skill_name = yuyun.name,
          })
          if #to > 0 then
            local id = room:askToChooseCard(player, {
              target = to[1],
              flag = "hej",
              skill_name = yuyun.name,
            })
            room:obtainCard(player, id, false, fk.ReasonPrey, player, yuyun.name)
          end
        end
      elseif choice == "yuyun5" then
        local targets = table.filter(room:getOtherPlayers(player, false), function(p)
          return p:getHandcardNum() < math.min(p.maxHp, 5)
        end)
        if #targets > 0 then
          local to = room:askToChoosePlayers(player, {
            targets = targets,
            min_num = 1,
            max_num = 1,
            prompt = "#yuyun5-choose",
            skill_name = yuyun.name,
          })
          if #to > 0 then
            local x = math.min(to[1].maxHp, 5) - to[1]:getHandcardNum()
            if x > 0 then
              to[1]:drawCards(x, yuyun.name)
            end
          end
        end
      end
    end
  end,
})

yuyun:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and
      table.find(data.tos, function (p)
        return table.contains(player:getTableMark("yuyun2-turn"), p.id)
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

yuyun:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card.trueName == "slash" and to and table.contains(player:getTableMark("yuyun2-turn"), to.id)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and card.trueName == "slash" and to and table.contains(player:getTableMark("yuyun2-turn"), to.id)
  end,
})

return yuyun
