local yaozuo = fk.CreateSkill {
  name = "yaozuo"
}

Fk:loadTranslationTable{
  ['yaozuo'] = '邀作',
  ['#yaozuo'] = '邀作：令所有其他角色选择是否交给你一张牌',
  ['@@yaozuo-turn'] = '伤害+1',
  ['#yaozuo-give'] = '邀作：是否交给 %src 一张牌，交出牌最快者可以令其发动〖撰文〗，不交出牌者本回合下次受到伤害+1',
  ['#yaozuoWinner'] = '%from “%arg” 最快的响应者是 %to',
  ['#yaozuo-choose'] = '邀作：请选择一名角色，令 %src 对其发动“撰文”',
  ['zhuanwen'] = '撰文',
  ['#yaozuo_trigger'] = '邀作',
  [':yaozuo'] = '出牌阶段限一次，你可以令所有其他角色选择是否交给你一张牌。然后交给你牌最快者选择另一名其他角色，你对其所选角色发动〖撰文〗；未交给你牌的角色，本回合你下次对其造成的伤害+1。',
  ['$yaozuo1'] = '明公馈墨，琳当还以锦绣。',
  ['$yaozuo2'] = '识时务者，应势而为，当为俊杰。',
}

yaozuo:addEffect('active', {
  anim_type = "control",
  prompt = "#yaozuo",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(yaozuo.name, Player.HistoryPhase) == 0 and
      #Fk:currentRoom().alive_players > 1
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:doIndicate(player.id, table.map(room:getOtherPlayers(player, false), Util.IdMapper))
    local targets = table.filter(room:getOtherPlayers(player), function (p)
      return not p:isNude()
    end)
    if #targets == 0 then
      for _, p in ipairs(room:getOtherPlayers(player)) do
        room:setPlayerMark(p, "@@yaozuo-turn", player.id)
      end
      return
    else
      local extra_data = {
        num = 1,
        min_num = 1,
        include_equip = true,
        skillName = yaozuo.name,
        pattern = ".",
      }
      local data = { "choose_cards_skill", "#yaozuo-give:"..player.id, true, extra_data }

      local req = Request:new(targets, "AskForUseActiveSkill")
      req.focus_text = yaozuo.name
      for _, p in ipairs(targets) do req:setData(p, data) end
      req:ask()
      local winners = req.winners -- winners[1]就是最快的 别人其次

      for _, p in ipairs(room:getOtherPlayers(player)) do
        if not table.contains(winners, p) then
          room:setPlayerMark(p, "@@yaozuo-turn", player.id)
        end
      end
      if #winners > 0 then
        room:sendLog{
          type = "#yaozuoWinner",
          from = player.id,
          to = {winners[1].id},
          arg = yaozuo.name,
          toast = true,
        }
        local moves = {}
        for _, p in ipairs(winners) do
          local replyCard = req:getResult(p).card
          local cards = replyCard.subcards
          table.insert(moves, {
            ids = cards,
            from = p.id,
            to = player.id,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonGive,
            proposer = p.id,
            skillName = yaozuo.name,
          })
        end
        room:moveCards(table.unpack(moves))
        if player.dead or winners[1].dead then return end
        targets = table.filter(room:getOtherPlayers(player), function (p)
          return p ~= winners[1] and not p:isKongcheng()
        end)
        if #targets == 0 then return end
        local to = room:askToChoosePlayers(winners[1], {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#yaozuo-choose:"..player.id,
          skill_name = yaozuo.name,
          cancelable = false
        })
        local zhuanwenSkill = Fk.skills["zhuanwen"]
        event:setCostData(zhuanwenSkill, {tos = to})
        player:broadcastSkillInvoke("zhuanwen")
        room:notifySkillInvoked(player, "zhuanwen", "control")
        zhuanwenSkill:use(fk.EventPhaseStart, player, player, data)
      end
    end
  end,
})

yaozuo:addEffect('trigger', {
  name = "#yaozuo_trigger",
  mute = true,
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target and target == player and data.to:getMark("@@yaozuo-turn") == player.id
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(data.to, "@@yaozuo-turn", 0)
    data.damage = data.damage + 1
  end,
})

return yaozuo
