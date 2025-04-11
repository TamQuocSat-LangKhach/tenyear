local yongjin = fk.CreateSkill {
  name = "ty_ex__yongjin",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ty_ex__yongjin"] = "勇进",
  [":ty_ex__yongjin"] = "限定技，出牌阶段，你可以依次移动场上至多三张装备牌。",

  ["#ty_ex__yongjin"] = "勇进：依次移动三张装备！",
  ["#ty_ex__yongjin-choose"] = "勇进：你可以移动场上的一张装备牌",

  ["$ty_ex__yongjin1"] = "鏖兵卫主，勇足以却敌！",
  ["$ty_ex__yongjin2"] = "勇不可挡，进则无退！",
}

yongjin:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty_ex__yongjin",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:usedSkillTimes(yongjin.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local excludeIds = {}
    for _ = 1, 3 do
      if #room:canMoveCardInBoard("e", nil, excludeIds) == 0 or player.dead then break end
      local tos = room:askToChooseToMoveCardInBoard(player, {
        skill_name = yongjin.name,
        flag = "e",
        prompt = "#ty_ex__yongjin-choose",
        cancelable = true,
        no_indicate = false,
        exclude_ids = excludeIds,
      })
      if #tos == 2 then
        local result = room:askToMoveCardInBoard(player, {
          target_one = tos[1],
          target_two = tos[2],
          skill_name = yongjin.name,
          flag = "e",
          exclude_ids = excludeIds,
        })
        if result then
          table.insert(excludeIds, result.card.id)
        else
          break
        end
      else
        break
      end
    end
  end,
})

return yongjin
