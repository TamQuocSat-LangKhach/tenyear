local shencai = fk.CreateSkill {
  name = "shencai"
}

Fk:loadTranslationTable{
  ['shencai'] = '神裁',
  ['#shencai-active'] = '发动神裁，选择一名其他角色，令其判定',
  ['xunshi'] = '巡使',
  ['@@shencai_chi'] = '笞',
  ['@@shencai_zhang'] = '杖',
  ['@@shencai_tu'] = '徒',
  ['@@shencai_liu'] = '流',
  ['@shencai_si'] = '死',
  ['#shencai_delay'] = '神裁',
  [':shencai'] = '出牌阶段限一次，你可以令一名其他角色进行判定，你获得判定牌。若判定牌包含以下内容，其获得（已有标记则改为修改）对应标记：<br>体力：“笞”标记，每次受到伤害后失去等量体力；<br>武器：“杖”标记，无法响应【杀】；<br>打出：“徒”标记，以此法外失去手牌后随机弃置一张手牌；<br>距离：“流”标记，结束阶段将武将牌翻面；<br>若判定牌不包含以上内容，该角色获得一个“死”标记且手牌上限减少其身上“死”标记个数，然后你获得其区域内一张牌。“死”标记个数大于场上存活人数的角色回合结束时，其直接死亡。',
  ['$shencai1'] = '我有三千炼狱，待汝万世轮回！',
  ['$shencai2'] = '纵汝王侯将相，亦须俯首待裁！',
}

-- Active Skill
shencai:addEffect('active', {
  name = "shencai",
  prompt = "#shencai-active",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  times = function(self, player)
    return player.phase == Player.Play and 1 + player:getMark("xunshi") - player:usedSkillTimes(shencai.name, Player.HistoryPhase) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(shencai.name, Player.HistoryPhase) < 1 + player:getMark("xunshi")
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local data = {
      who = target,
      reason = shencai.name,
      pattern = ".",
      extra_data = {shencaiSource = effect.from}
    }
    room:judge(data)
    local result = {}
    if table.contains({"peach", "analeptic", "silver_lion", "god_salvation", "celestial_calabash"}, data.card.trueName) then
      table.insert(result, "@@shencai_chi")
    end
    if data.card.sub_type == Card.SubtypeWeapon or data.card.name == "collateral" then
      table.insert(result, "@@shencai_zhang")
    end
    if table.contains({"savage_assault", "archery_attack", "duel", "spear", "eight_diagram", "raid_and_frontal_attack"}, data.card.trueName) then
      table.insert(result, "@@shencai_tu")
    end
    if data.card.sub_type == Card.SubtypeDefensiveRide or data.card.sub_type == Card.SubtypeOffensiveRide or
      table.contains({"snatch", "supply_shortage", "chasing_near"}, data.card.trueName) then
      table.insert(result, "@@shencai_liu")
    end
    if #result == 0 then
      table.insert(result, "@shencai_si")
    end
    if result[1] ~= "@shencai_si" then
      for _, mark in ipairs({"@@shencai_chi", "@@shencai_zhang", "@@shencai_tu", "@@shencai_liu"}) do
        room:setPlayerMark(data.who, mark, 0)
      end
    end
    for _, mark in ipairs(result) do
      room:addPlayerMark(data.who, mark, 1)
      if mark == "@shencai_si" and not data.who:isNude() then
        local card = room:askToChooseCard(player, {
          target = target,
          flag = "he",
          skill_name = shencai.name
        })
        room:obtainCard(player.id, card, false, fk.ReasonPrey)
      end
    end
  end,
})

-- Trigger Skill
shencai:addEffect(fk.FinishJudge | fk.Damaged | fk.TargetConfirmed | fk.AfterCardsMove | fk.EventPhaseStart | fk.TurnEnd, {
  name = "#shencai_delay",
  anim_type = "offensive",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player.dead then return false end
    if event == fk.FinishJudge then
      return data.extra_data and data.extra_data.shencaiSource == player.id and player.room:getCardArea(data.card) == Card.Processing
    elseif event == fk.Damaged then
      return player == target and player:getMark("@@shencai_chi") > 0
    elseif event == fk.TargetConfirmed then
      return player == target and data.card.trueName == "slash" and player:getMark("@@shencai_zhang") > 0
    elseif event == fk.AfterCardsMove and player:getMark("@@shencai_tu") > 0 and not player:isKongcheng() then
      for _, move in ipairs(data) do
        if move.skillName ~= shencai.name and move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    elseif event == fk.EventPhaseStart then
      return player == target and player:getMark("@@shencai_liu") > 0 and player.phase == Player.Finish
    elseif event == fk.TurnEnd then
      return player == target and player:getMark("@shencai_si") > #player.room.alive_players
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.FinishJudge then
      if room:getCardArea(data.card) == Card.Processing then
        room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
      end
      return false
    end
    room:notifySkillInvoked(player, shencai.name, "negative")
    player:broadcastSkillInvoke(shencai.name)
    if event == fk.Damaged then
      room:loseHp(player, data.damage, shencai.name)
    elseif event == fk.TargetConfirmed then
      data.disresponsive = true
    elseif event == fk.AfterCardsMove then
      local cards = table.filter(player.player_cards[Player.Hand], function (id)
        return not player:prohibitDiscard(Fk:getCardById(id))
      end)
      if #cards > 0 then
        room:throwCard(table.random(cards, 1), shencai.name, player, player)
      end
    elseif event == fk.EventPhaseStart then
      player:turnOver()
    elseif event == fk.TurnEnd then
      room:killPlayer({who = player.id})
    end
  end,

  on_lose = function (self, player)
    player.room:setPlayerMark(player, "xunshi", 0)
  end,
})

-- MaxCards Skill
shencai:addEffect('maxcards', {
  name = "#shencai_maxcards",
  correct_func = function(self, player)
    return -player:getMark("@shencai_si")
  end,
})

return shencai
