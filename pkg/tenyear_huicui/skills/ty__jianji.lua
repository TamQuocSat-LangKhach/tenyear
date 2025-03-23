local ty__jianji = fk.CreateSkill {
  name = "ty__jianji"
}

Fk:loadTranslationTable{
  ['ty__jianji'] = '间计',
  ['#ty__jianji-prompt'] = '间计:令至多 %arg 名相邻的角色各弃置一张牌',
  ['#ty__jianji-from'] = '间计：选择视为使用【杀】的角色',
  ['#ty__jianji-choose'] = '间计：你可以视为对其中一名角色使用【杀】',
  [':ty__jianji'] = '出牌阶段限一次，你可以令至多X名相邻的角色各弃置一张牌（X为你的攻击范围），然后你令其中手牌数最多的一名角色选择是否视为对其中的另一名角色使用一张【杀】。',
  ['$ty__jianji1'] = '备枭雄也，布虓虎也，当间之。',
  ['$ty__jianji2'] = '二虎和则我亡，二虎斗则我兴。',
}

ty__jianji:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = function(player)
    return player:getAttackRange()
  end,
  prompt = function (player)
    return "#ty__jianji-prompt:::"..player:getAttackRange()
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(ty__jianji.name, Player.HistoryPhase) == 0 and player:getAttackRange() > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if #selected < player:getAttackRange() and not target:isRemoved() then
      if #selected == 0 then
        return true
      else
        for _, id in ipairs(selected) do
          local p = Fk:currentRoom():getPlayerById(id)
          if target:getNextAlive() == p or p:getNextAlive() == target then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local tos = effect.tos
    room:sortPlayersByAction(tos)
    tos = table.map(tos, Util.Id2PlayerMapper)
    for _, p in ipairs(tos) do
      room:askToDiscard(p, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = ty__jianji.name,
        cancelable = false,
      })
    end
    tos = table.filter(tos, function(p) return not p.dead end)
    if #tos < 2 then return end
    local max_num = 0
    for _, p in ipairs(tos) do
      max_num = math.max(max_num, p:getHandcardNum())
    end
    local froms = table.filter(tos, function(p) return p:getHandcardNum() == max_num end)
    local from = (#froms == 1) and froms[1] or room:getPlayerById(
      room:askToChoosePlayers(player, {
        targets = table.map(froms, Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#ty__jianji-from",
        skill_name = ty__jianji.name,
        cancelable = false
      })[1])
    local targets = table.filter(tos, function(p)
      return not p.dead and from:canUseTo(Fk:cloneCard("slash"), p, {bypass_times = true, bypass_distances = true})
    end)
    if #targets > 0 then
      local victim = room:askToChoosePlayers(from, {
        targets = table.map(targets, Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#ty__jianji-choose",
        skill_name = ty__jianji.name,
        cancelable = true
      })
      if #victim > 0 then
        room:useVirtualCard("slash", nil, from, room:getPlayerById(victim[1]), ty__jianji.name, true)
      end
    end
  end,
})

return ty__jianji
