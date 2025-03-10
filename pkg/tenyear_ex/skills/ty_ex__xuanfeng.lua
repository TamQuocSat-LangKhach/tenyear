local ty_ex__xuanfeng = fk.CreateSkill {
  name = "ty_ex__xuanfeng"
}

Fk:loadTranslationTable{
  ['ty_ex__xuanfeng'] = '旋风',
  ['#ty_ex__xuanfeng-choose'] = '旋风：你可以依次弃置一至两名其他角色的共计两张牌',
  ['#ty_ex__xuanfeng-damage'] = '旋风：你可以对其中一名角色造成一点伤害。',
  [':ty_ex__xuanfeng'] = '当你失去装备区里的牌，或于弃牌阶段弃掉两张或更多的牌时，若没有角色处于濒死状态，你可以依次弃置一至两名其他角色的共计两张牌。若此时是你的回合内，则你可以对其中一名角色造成1点伤害。',
  ['$ty_ex__xuanfeng1'] = '风动扬帆起，枪出敌军溃！',
  ['$ty_ex__xuanfeng2'] = '御风而动，敌军四散！',
}

ty_ex__xuanfeng:addEffect({
  events = {fk.AfterCardsMove, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(ty_ex__xuanfeng) and table.every(player.room.alive_players, function(p) return not p.dying end)
      and table.find(player.room.alive_players, function(p) return not p:isNude() and p ~= player end) then
      if event == fk.AfterCardsMove then
        for _, move in ipairs(data) do
          if move.from == player.id then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerEquip then
                return true
              end
            end
          end
        end
      elseif event == fk.EventPhaseEnd then
        if target == player and player.phase == Player.Discard then
          local x = 0
          local logic = player.room.logic
          logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
            for _, move in ipairs(e.data) do
              if move.from == player.id and move.moveReason == fk.ReasonDiscard and move.skillName == "phase_discard" then
                x = x + #move.moveInfo
                if x > 1 then return true end
              end
            end
            return false
          end, Player.HistoryTurn)
          return x > 1
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p) return not p:isNude() and p ~= player end)
    if #targets == 0 then return false end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty_ex__xuanfeng-choose",
      skill_name = ty_ex__xuanfeng.name,
      cancelable = true
    })
    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local victims = {event:getCostData(self)}
    local to = room:getPlayerById(event:getCostData(self))
    local card = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = ty_ex__xuanfeng.name
    })
    room:throwCard({card}, ty_ex__xuanfeng.name, to, player)
    if player.dead then return false end
    local targets = table.filter(room.alive_players, function(p) return not p:isNude() and p ~= player end)
    if #targets > 0 then
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#ty_ex__xuanfeng-choose",
        skill_name = ty_ex__xuanfeng.name,
        cancelable = true
      })
      if #tos > 0 then
        table.insertIfNeed(victims, tos[1])
        to = room:getPlayerById(tos[1])
        card = room:askToChooseCard(player, {
          target = to,
          flag = "he",
          skill_name = ty_ex__xuanfeng.name
        })
        room:throwCard({card}, ty_ex__xuanfeng.name, to, player)
        if player.dead then return false end
      end
    end
    if room.current == player then
      local tos = room:askToChoosePlayers(player, {
        targets = victims,
        min_num = 1,
        max_num = 1,
        prompt = "#ty_ex__xuanfeng-damage",
        skill_name = ty_ex__xuanfeng.name,
        cancelable = true
      })
      if #tos > 0 then
        room:damage{
          from = player,
          to = room:getPlayerById(tos[1]),
          damage = 1,
          skillName = ty_ex__xuanfeng.name,
        }
      end
    end
  end,
})

return ty_ex__xuanfeng
