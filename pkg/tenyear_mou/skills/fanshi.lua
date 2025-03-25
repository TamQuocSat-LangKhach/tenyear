local fanshi = fk.CreateSkill {
  name = "fanshi",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["fanshi"] = "返势",
  [":fanshi"] = "觉醒技，结束阶段，若〖渐专〗的选项数小于2，你依次执行3次剩余项（X视为1），加2点体力上限并回复2点体力，失去〖渐专〗，获得〖覆斗〗。",

  ["$fanshi1"] = "垒巨木为寨，发屯兵自守。",
  ["$fanshi2"] = "吾居伊周之位，怎可以罪见黜？",
}

fanshi:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and player:hasSkill(fanshi.name) and
      player:hasSkill("jianzhuan", true) and
      player:usedSkillTimes(fanshi.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    local x = 0
    for i = 1, 4 do
      if player:getMark("jianzhuan"..tostring(i)) == 0 then
        x = x + 1
      end
    end
    return x < 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = ""
    for i = 1, 4 do
      choice = "jianzhuan"..i
      if player:getMark(choice) == 0 then
        for _ = 1, 3 do
          if choice == "jianzhuan1" then
            if #room:getOtherPlayers(player, false) == 0 then return end
            local to = room:askToChoosePlayers(player, {
              min_num = 1,
              max_num = 1,
              targets = room:getOtherPlayers(player, false),
              skill_name = "jianzhuan",
              prompt = "#jianzhuan-choose:::1",
              cancelable = false,
            })[1]
            room:askToDiscard(to, {
              min_num = 1,
              max_num = 1,
              include_equip = true,
              skill_name = "jianzhuan",
              cancelable = false,
            })
          elseif choice == "jianzhuan2" then
            player:drawCards(1, "jianzhuan")
          elseif choice == "jianzhuan3" then
            if player:isNude() then return end
            local cards = player:getCardIds("he")
            if #cards > 1 then
              cards = room:askToCards(player, {
                min_num = 1,
                max_num = 1,
                include_equip = true,
                skill_name = "jianzhuan",
                prompt = "#jianzhuan-recast:::1",
                cancelable = false,
              })
            end
            room:recastCard(cards, player, "jianzhuan")
          elseif choice == "jianzhuan4" then
            room:askToDiscard(player, {
              min_num = 1,
              max_num = 1,
              include_equip = true,
              skill_name = "jianzhuan",
              cancelable = false,
            })
          end
          if player.dead then return false end
        end
        break
      end
    end
    room:changeMaxHp(player, 2)
    if player.dead then return false end
    if player:isWounded() then
      room:recover{
        who = player,
        num = 2,
        recoverBy = player,
        skillName = fanshi.name,
      }
      if player.dead then return false end
    end
    room:handleAddLoseSkills(player, "-jianzhuan|fudou")
  end,
})

return fanshi
