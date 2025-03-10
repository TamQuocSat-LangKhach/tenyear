local yuyun = fk.CreateSkill {
  name = "yuyun"
}

Fk:loadTranslationTable{
  ['yuyun'] = '玉陨',
  ['yuyun1'] = '摸两张牌',
  ['yuyun2'] = '对一名其他角色造成1点伤害，本回合对其使用【杀】无距离和次数限制',
  ['yuyun3'] = '本回合没有手牌上限',
  ['yuyun4'] = '获得一名其他角色区域内的一张牌',
  ['yuyun5'] = '令一名其他角色将手牌摸至体力上限（最多摸至5）',
  ['#yuyun2-choose'] = '玉陨：对一名其他角色造成1点伤害，本回合对其使用【杀】无距离和次数限制',
  ['@@yuyun-turn'] = '玉陨',
  ['#yuyun4-choose'] = '玉陨：获得一名其他角色区域内的一张牌',
  ['#yuyun5-choose'] = '玉陨：令一名其他角色将手牌摸至体力上限（最多摸至5）',
  [':yuyun'] = '锁定技，出牌阶段开始时，你失去1点体力或体力上限（你的体力上限不能以此法被减至1以下），然后选择X+1项（X为你已损失的体力值）：<br>1.摸两张牌；<br>2.对一名其他角色造成1点伤害，然后本回合对其使用【杀】无距离和次数限制；<br>3.本回合没有手牌上限；<br>4.获得一名其他角色区域内的一张牌；<br>5.令一名其他角色将手牌摸至体力上限（最多摸至5）。',
  ['$yuyun1'] = '春依旧，人消瘦。',
  ['$yuyun2'] = '泪沾青衫，玉殒香消。',
}

yuyun:addEffect(fk.EventPhaseStart, {
  global = false,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(yuyun.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local chs = {"loseHp"}
    if player.maxHp > 1 then table.insert(chs, "loseMaxHp") end
    local chc = room:askToChoice(player, {
      choices = chs,
      skill_name = yuyun.name
    })
    if chc == "loseMaxHp" then
      room:changeMaxHp(player, -1)
    else
      room:loseHp(player, 1, yuyun.name)
    end
    local choices = {"yuyun1", "yuyun2", "yuyun3", "yuyun4", "yuyun5", "Cancel"}
    local n = 1 + player:getLostHp()
    for i = 1, n do
      if player.dead or #choices < 2 then return end
      local choice = room:askToChoice(player, {
        choices = choices,
        skill_name = yuyun.name
      })
      if choice == "Cancel" then return end
      table.removeOne(choices, choice)
      if choice == "yuyun1" then
        player:drawCards(2, yuyun.name)
      elseif choice == "yuyun2" then
        local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
        if #targets > 0 then
          local to = room:askToChoosePlayers(player, {
            targets = targets,
            min_num = 1,
            max_num = 1,
            prompt = "#yuyun2-choose",
            skill_name = yuyun.name
          })
          if #to > 0 then
            local tar = room:getPlayerById(to[1])
            room:damage{
              from = player,
              to = tar,
              damage = 1,
              skillName = yuyun.name,
            }
            if not tar.dead then
              room:addPlayerMark(tar, "@@yuyun-turn")
              room:addTableMarkIfNeed(player, "yuyun2-turn", to[1])
            end
          end
        end
      elseif choice == "yuyun3" then
        room:addPlayerMark(player, "@@yuyun-turn")
        room:addPlayerMark(player, "yuyun3-turn", 1)
      elseif choice == "yuyun4" then
        local targets = table.map(table.filter(room:getOtherPlayers(player, false), function(p)
          return not p:isAllNude() end), Util.IdMapper)
        if #targets > 0 then
          local to = room:askToChoosePlayers(player, {
            targets = targets,
            min_num = 1,
            max_num = 1,
            prompt = "#yuyun4-choose",
            skill_name = yuyun.name
          })
          if #to > 0 then
            local id = room:askToChooseCard(player, {
              target = room:getPlayerById(to[1]),
              flag = "hej",
              skill_name = yuyun.name
            })
            room:obtainCard(player.id, id, false, fk.ReasonPrey)
          end
        end
      elseif choice == "yuyun5" then
        local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
        if #targets > 0 then
          local to = room:askToChoosePlayers(player, {
            targets = targets,
            min_num = 1,
            max_num = 1,
            prompt = "#yuyun5-choose",
            skill_name = yuyun.name
          })
          if #to > 0 then
            local p = room:getPlayerById(to[1])
            local x = math.min(p.maxHp, 5) - p:getHandcardNum()
            if x > 0 then
              room:drawCards(p, x, yuyun.name)
            end
          end
        end
      end
    end
  end,
})

yuyun:addEffect(fk.PreCardUse, {
  global = false,
  can_refresh = function(self, event, target, player, data)
    if player == target and data.card.trueName == "slash" then
      local mark = player:getTableMark("yuyun2-turn")
      return #mark > 0 and table.find(TargetGroup:getRealTargets(data.tos), function (pid)
        return table.contains(mark, pid)
      end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

yuyun:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card.trueName == "slash" and to and table.contains(player:getTableMark("yuyun2-turn"), to.id)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and card.trueName == "slash" and to and table.contains(player:getTableMark("yuyun2-turn"), to.id)
  end,
})

yuyun:addEffect('maxcards', {
  exclude_from = function(self, player, card)
    return player:getMark("yuyun3-turn") > 0
  end,
})

return yuyun
