local ex__yongjin = fk.CreateSkill {
  name = "ex__yongjin"
}

Fk:loadTranslationTable{
  ['ex__yongjin'] = '勇进',
  ['#ex__yongjin-choose'] = '勇进：你可以移动场上的一张装备牌',
  [':ex__yongjin'] = '限定技，出牌阶段，你可以依次移动场上至多三张装备牌。',
  ['$ex__yongjin1'] = '鏖兵卫主，勇足以却敌！',
  ['$ex__yongjin2'] = '勇不可挡，进则无退！',
}

ex__yongjin:addEffect('active', {
  anim_type = "offensive",
  frequency = Skill.Limited,
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:usedSkillTimes(ex__yongjin.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local excludeIds = {}
    for i = 1, 3, 1 do
      if #room:canMoveCardInBoard("e", nil, excludeIds) == 0 or player.dead then break end
      local to = room:askToChooseToMoveCardInBoard(player, {
        skill_name = ex__yongjin.name,
        flag = "e",
        cancelable = true,
        no_indicate = false,
        exclude_ids = excludeIds
      })
      if #to == 2 then
        local result = room:askToMoveCardInBoard(player, {
          target_one = room:getPlayerById(to[1]),
          target_two = room:getPlayerById(to[2]),
          skill_name = ex__yongjin.name,
          flag = "e",
          exclude_ids = excludeIds
        })
        if result then
          table.insert(excludeIds, result.card:getEffectiveId())
        else
          break
        end
      else
        break
      end
    end
  end,
})

return ex__yongjin
