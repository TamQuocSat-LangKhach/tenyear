local lueming = fk.CreateSkill {
  name = "lueming",
}

Fk:loadTranslationTable{
  ["lueming"] = "掠命",
  [":lueming"] = "出牌阶段限一次，你选择一名装备区装备少于你的其他角色，令其选择一个点数，然后你进行判定：若点数相同，你对其造成2点伤害；"..
  "不同，你随机获得其区域内的一张牌。",

  ["#lueming"] = "掠命：令一名角色猜测判定牌点数，若相同则对其造成2点伤害，不同则你获得其牌",

  ["$lueming1"] = "劫命掠财，毫不费力。",
  ["$lueming2"] = "人财，皆掠之，哈哈！",
}

lueming:addEffect("active", {
  anim_type = "offensive",
  prompt = "#lueming",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(lueming.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and #to_select:getCardIds("e") < #player:getCardIds("e")
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local choices = {}
    for i = 1, 13, 1 do
      table.insert(choices, tostring(i))
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = lueming.name,
    })
    room:sendLog{
      type = "#Choice",
      from = target.id,
      arg = choice,
      toast = true,
    }
    local judge = {
      who = player,
      reason = lueming.name,
      pattern = ".",
    }
    room:judge(judge)
    if tostring(judge.card.number) == choice then
      room:damage{
        from = player,
        to = target,
        damage = 2,
        skillName = lueming.name,
      }
    elseif not target:isAllNude() then
      room:obtainCard(player, table.random(target:getCardIds("hej")), false, fk.ReasonPrey, player, lueming.name)
    end
  end,
})

return lueming
