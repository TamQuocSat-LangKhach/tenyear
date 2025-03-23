local ty__mouzhu = fk.CreateSkill {
  name = "ty__mouzhu"
}

Fk:loadTranslationTable{
  ['ty__mouzhu'] = '谋诛',
  ['#mouzhu-give'] = '谋诛：交给%dest一张手牌，然后若你手牌数小于其，视为你对其使用【杀】或【决斗】',
  [':ty__mouzhu'] = '出牌阶段限一次，你可以选择任意名与你距离为1或体力值与你相同的其他角色，依次将一张手牌交给你，然后若其手牌数小于你，其视为对你使用一张【杀】或【决斗】。',
  ['$ty__mouzhu1'] = '尔等祸乱朝纲，罪无可赦，按律当诛！',
  ['$ty__mouzhu2'] = '天下人之怨皆系于汝等，还不快认罪伏法？',
}

ty__mouzhu:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  min_target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(ty__mouzhu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return to_select ~= player.id and (target:distanceTo(player) == 1 or target.hp == player.hp) and not target:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for _, p in ipairs(effect.tos) do
      local target = room:getPlayerById(p)
      if player.dead or target.dead then return end
      if not target:isKongcheng() then
        local card = room:askToCards(target, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          skill_name = ty__mouzhu.name,
          cancelable = false,
          prompt = "#mouzhu-give::"..player.id
        })
        room:obtainCard(player, card[1], false, fk.ReasonGive, target.id)
        if #player.player_cards[Player.Hand] > #target.player_cards[Player.Hand] then
          local choice = room:askToChoice(target, {
            choices = {"slash", "duel"},
            skill_name = ty__mouzhu.name,
          })
          room:useVirtualCard(choice, nil, target, player, ty__mouzhu.name, true)
        end
      end
    end
  end,
})

return ty__mouzhu
