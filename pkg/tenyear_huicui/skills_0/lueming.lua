local lueming = fk.CreateSkill {
  name = "lueming"
}

Fk:loadTranslationTable{
  ['lueming'] = '掠命',
  [':lueming'] = '出牌阶段限一次，你选择一名装备区装备少于你的其他角色，令其选择一个点数，然后你进行判定：若点数相同，你对其造成2点伤害；不同，你随机获得其区域内的一张牌。',
  ['$lueming1'] = '劫命掠财，毫不费力。',
  ['$lueming2'] = '人财，皆掠之，哈哈！',
}

lueming:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(lueming.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and #target.player_cards[Player.Equip] < #player.player_cards[Player.Equip]
  end,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local target = room:getPlayerById(use.tos[1])
    local choices = {}
    for i = 1, 13, 1 do
      table.insert(choices, tostring(i))
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = lueming.name
    })
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
      local id = table.random(target:getCardIds{Player.Hand, Player.Equip, Player.Judge})
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end,
})

return lueming
