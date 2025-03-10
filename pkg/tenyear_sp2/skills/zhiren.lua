local zhiren = fk.CreateSkill {
  name = "zhiren"
}

Fk:loadTranslationTable{
  ['zhiren'] = '织纴',
  ['@@yaner'] = '燕尔',
  ['#zhiren1-choose'] = '织纴：你可以弃置场上一张装备牌',
  ['#zhiren2-choose'] = '织纴：你可以弃置场上一张延时锦囊牌',
  [':zhiren'] = '你的回合内，当你使用本回合的第一张非转化牌时，若X：不小于1，你观看牌堆顶X张牌并以任意顺序放回牌堆顶或牌堆底；不小于2，你可以弃置场上一张装备牌和一张延时锦囊牌；不小于3，你回复1点体力；不小于4，你摸三张牌（X为此牌名称字数）。',
  ['$zhiren1'] = '穿针引线，栩栩如生。',
  ['$zhiren2'] = '纺绩织纴，布帛可成。',
}

zhiren:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zhiren.name) and not data.card:isVirtual() and
      (player.phase ~= Player.NotActive or player:getMark("@@yaner") > 0) then
      local room = player.room
      local logic = room.logic
      local use_event = logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local mark = player:getMark("zhiren_record-turn")
      if mark == 0 then
        logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
          local last_use = e.data[1]
          if last_use.from == player.id and not last_use.card:isVirtual() then
            mark = e.id
            room:setPlayerMark(player, "zhiren_record-turn", mark)
            return true
          end
          return false
        end, Player.HistoryTurn)
      end
      return mark == use_event.id
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = Fk:translate(data.card.trueName, "zh_CN"):len()
    room:askToGuanxing(player, {
      cards = room:getNCards(n),
      skill_name = zhiren.name,
    })
    if n > 1 then
      local targets = table.map(table.filter(room.alive_players, function(p)
        return #p.player_cards[Player.Equip] > 0 end), Util.IdMapper)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#zhiren1-choose",
          skill_name = zhiren.name,
        })
        if #to > 0 then
          to = room:getPlayerById(to[1])
          local id = room:askToChooseCard(player, {
            target = to,
            flag = "e",
            skill_name = zhiren.name,
          })
          room:throwCard({id}, zhiren.name, to, player)
          if player.dead then return false end
        end
      end
      targets = table.map(table.filter(room.alive_players, function(p)
        return #p.player_cards[Player.Judge] > 0 end), Util.IdMapper)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          targets = targets,
          min_num = 1,
          max_num = 1,
          prompt = "#zhiren2-choose",
          skill_name = zhiren.name,
        })
        if #to > 0 then
          to = room:getPlayerById(to[1])
          local id = room:askToChooseCard(player, {
            target = to,
            flag = "j",
            skill_name = zhiren.name,
          })
          room:throwCard({id}, zhiren.name, to, player)
          if player.dead then return false end
        end
      end
    end
    if n > 2 then
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = zhiren.name
        }
        if player.dead then return false end
      end
    end
    if n > 3 then
      room:drawCards(player, 3, zhiren.name)
    end
  end,
})

return zhiren
