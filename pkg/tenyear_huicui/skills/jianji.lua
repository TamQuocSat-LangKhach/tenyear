local jianji = fk.CreateSkill {
  name = "ty__jianji",
}

Fk:loadTranslationTable{
  ["ty__jianji"] = "间计",
  [":ty__jianji"] = "出牌阶段限一次，你可以令至多X名相邻的角色各弃置一张牌（X为你的攻击范围），然后你令其中手牌数最多的一名角色"..
  "选择是否视为对其中的另一名角色使用一张【杀】。",

  ["#ty__jianji"] = "间计：令至多 %arg 名相邻的角色各弃置一张牌",
  ["#ty__jianji-choose"] = "间计：选择一名角色，其可以视为使用【杀】",
  ["#ty__jianji-slash"] = "间计：你可以视为对其中一名角色使用【杀】",

  ["$ty__jianji1"] = "备枭雄也，布虓虎也，当间之。",
  ["$ty__jianji2"] = "二虎和则我亡，二虎斗则我兴。",
}

jianji:addEffect("active", {
  anim_type = "control",
  prompt = function (self, player)
    return "#ty__jianji:::"..player:getAttackRange()
  end,
  card_num = 0,
  min_target_num = 1,
  max_target_num = function(self, player)
    return player:getAttackRange()
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(jianji.name, Player.HistoryPhase) == 0 and player:getAttackRange() > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected < player:getAttackRange() and not to_select:isRemoved() then
      if #selected == 0 then
        return true
      else
        for _, p in ipairs(selected) do
          if to_select:getNextAlive() == p or p:getNextAlive() == to_select then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local targets = table.simpleClone(effect.tos)
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      if not p.dead then
        room:askToDiscard(p, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = jianji.name,
          cancelable = false,
        })
      end
    end
    targets = table.filter(targets, function(p)
      return not p.dead
    end)
    if #targets < 2 then return end
    local tos = table.filter(targets, function(p)
      return table.every(targets, function(q)
        return p:getHandcardNum() >= q:getHandcardNum()
      end)
    end)
    local to = tos[1]
    if #tos > 1 then
      to = room:askToChoosePlayers(player, {
        targets = tos,
        min_num = 1,
        max_num = 1,
        prompt = "#ty__jianji-choose",
        skill_name = jianji.name,
        cancelable = false,
      })[1]
    end
    room:askToUseVirtualCard(to, {
      name = "slash",
      skill_name = jianji.name,
      prompt = "#ty__jianji-slash",
      cancelable = true,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
        exclusive_targets = table.map(targets, Util.IdMapper)
      },
    })
  end,
})

return jianji
