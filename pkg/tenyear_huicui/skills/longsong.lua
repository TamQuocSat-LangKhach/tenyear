local longsong = fk.CreateSkill {
  name = "longsong",
}

Fk:loadTranslationTable{
  ["longsong"] = "龙诵",
  [":longsong"] = "出牌阶段开始时，你可以交给或随机获得一名其他角色一张红色牌，然后你本阶段获得一个“出牌阶段”的技能"..
  "（优先获得该角色的技能，若未获得则改为随机获得一个技能池中的技能，只能发动一次）。",

  ["#longsong-invoke"] = "龙诵：交给或获得一名角色一张红色牌，本阶段获得其拥有的一个“出牌阶段”技能",

  ["$longsong1"] = "百家诸子，且听九霄龙吟。",
  ["$longsong2"] = "朗朗书声，岂虚于刀斧铮鸣。",
}

longsong:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(longsong.name) and player.phase == Player.Play and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 0,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      pattern = ".|.|heart,diamond",
      prompt = "#longsong-invoke",
      skill_name = longsong.name,
      cancelable = true,
    })
    if #tos == 1 then
      event:setCostData(self, {tos = tos, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = event:getCostData(self).cards
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, longsong.name, nil, false, player)
    else
      cards = table.filter(to:getCardIds("he"), function(id)
        return Fk:getCardById(id).color == Card.Red
      end)
      if #cards > 0 then
        room:moveCardTo(table.random(cards), Card.PlayerHand, player, fk.ReasonPrey, longsong.name, nil, false, player)
      end
    end
    if player.dead then return end

    local longsong_skills = {}
    if Fk.skill_skels["ty__pingjian"] then
      longsong_skills = Fk.skill_skels["ty__pingjian"].pinjian_skills["play"]
    end
    local skills = {}
    local ban_list = { }  --待定
    for _, s in ipairs(to:getSkillNameList()) do
      if not table.contains(ban_list, s) and not player:hasSkill(s, true) and #Fk.skill_skels[s].tags == 0 then
        local skill = Fk.skills[s]
        if table.contains(longsong_skills, s) then
          table.insertIfNeed(skills, s)
        elseif skill:isInstanceOf(ActiveSkill) or skill:isInstanceOf(ViewAsSkill) then
          if Fk:translate(":"..s, "zh_CN"):startsWith("出牌阶段") then
            table.insertIfNeed(skills, s)
          end
        end
      end
    end
    if #skills == 0 then
      skills = table.filter(longsong_skills, function (skill_name)
        return Fk.skills[skill_name] and not player:hasSkill(skill_name, true)
      end)
    end
    if #skills > 0 then
      local skill = table.random(skills)
      room:setPlayerMark(player, "longsong-phase", skill)
      room:handleAddLoseSkills(player, skill)
      room.logic:getCurrentEvent():findParent(GameEvent.Phase):addCleaner(function()
        room:handleAddLoseSkills(player, "-"..skill)
      end)
    end
  end,
})

longsong:addEffect("invalidity", {
  invalidity_func = function(self, from, skill)
    return from:getMark("longsong-phase") == skill:getSkeleton().name and
      from:usedSkillTimes(skill:getSkeleton().name, Player.HistoryPhase) > 0
  end
})

return longsong
