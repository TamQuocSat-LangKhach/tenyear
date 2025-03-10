local xiyan = fk.CreateSkill {
  name = "xiyan"
}

Fk:loadTranslationTable{
  ['xiyan'] = '夕颜',
  ['#yuanyu_resent'] = '怨',
  ['@@yuanyu'] = '怨语',
  ['#xiyan-debuff'] = '夕颜：是否令%dest本回合不能使用基本牌且手牌上限-4',
  ['@@xiyan_prohibit-turn'] = '夕颜 不能出牌',
  [':xiyan'] = '每次增加“怨”时，若“怨”的花色数达到4种，你可以获得所有“怨”。然后若此时是你的回合，你的〖怨语〗视为未发动过，本回合手牌上限+4且使用牌无次数限制；若不是你的回合，你可令当前回合角色本回合手牌上限-4且本回合不能使用基本牌。',
  ['$xiyan1'] = '夕阳绝美，只叹黄昏。',
  ['$xiyan2'] = '朱颜将逝，知我何求。',
}

xiyan:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(xiyan.name) then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerSpecial and move.specialName == "#yuanyu_resent" then
          local suits = {}
          for _, id in ipairs(player:getPile("#yuanyu_resent")) do
            table.insertIfNeed(suits, Fk:getCardById(id).suit)
          end
          table.removeOne(suits, Card.NoSuit)
          return #suits > 3
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = player:getMark("yuanyu_targets")
    if type(targets) == "table" then
      for _, pid in ipairs(targets) do
        room:removePlayerMark(room:getPlayerById(pid), "@@yuanyu")
      end
    end
    room:setPlayerMark(player, "yuanyu_targets", 0)
    room:moveCardTo(player:getPile("#yuanyu_resent"), Card.PlayerHand, player, fk.ReasonJustMove, xiyan.name, nil, true, player.id)
    if room.current and not room.current.dead and room.current.phase ~= Player.NotActive then
      if room.current == player then
        room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 4)
        if player:usedSkillTimes(yuanyu.name, Player.HistoryPhase) > player:getMark("yuanyu_extra_times-phase") then
          room:addPlayerMark(player, "yuanyu_extra_times-phase")
        end
        room:addPlayerMark(player, "xiyan_targetmod-turn")
      elseif room:askToSkillInvoke(player, {
          skill_name = xiyan.name,
          prompt = "#xiyan-debuff::" .. room.current.id
        }) then
        room:addPlayerMark(room.current, MarkEnum.MinusMaxCardsInTurn, 4)
        room:addPlayerMark(room.current, "@@xiyan_prohibit-turn")
      end
    end
  end,
})

xiyan:addEffect('targetmod', {
  name = "#xiyan_targetmod",
  bypass_times = function(self, player, skill, scope, card, to)
    return card and player:getMark("xiyan_targetmod-turn") > 0
  end,
})

xiyan:addEffect('prohibit', {
  name = "#xiyan_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@@xiyan_prohibit-turn") > 0 and card.type == Card.TypeBasic
  end,
})

return xiyan
