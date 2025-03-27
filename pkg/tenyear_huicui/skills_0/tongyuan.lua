local tongyuan = fk.CreateSkill {
  name = "tongyuan"
}

Fk:loadTranslationTable{
  ['tongyuan'] = '同援',
  ['tongyuan1'] = '没闪摸牌',
  ['tongyuan2'] = '不用给牌',
  ['@tongyuan'] = '同援',
  ['tongyuan_all'] = '全部生效',
  ['#tongyuan_delay'] = '同援',
  ['#tongyuan-choose'] = '同援：你可以为%arg额外指定一个目标',
  [':tongyuan'] = '锁定技，你使用红色锦囊牌后，〖摧坚〗增加效果“若其没有【闪】，你摸两张牌”；<br>你使用或打出红色基本牌后，〖摧坚〗将“交给”的效果删除；<br>若以上两个效果均已触发，则你本局游戏接下来你使用红色普通锦囊牌无法被响应，使用红色基本牌可以额外指定一个目标。',
  ['$tongyuan1'] = '乐将军何在？随我共援上方谷！',
  ['$tongyuan2'] = '袍泽有难，岂有坐视之理？',
}

tongyuan:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(tongyuan.name) and data.card.color == Card.Red then
      if data.card.type == Card.TypeTrick then
        return player:getMark("tongyuan1") == 0
      elseif data.card.type == Card.TypeBasic then
        return player:getMark("tongyuan2") == 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.type == Card.TypeTrick then
      room:setPlayerMark(player, "tongyuan1", 1)
      room:setPlayerMark(player, "@tongyuan", player:getMark("tongyuan2") > 0 and "tongyuan_all" or "tongyuan1")
    else
      room:setPlayerMark(player, "tongyuan2", 1)
      room:setPlayerMark(player, "@tongyuan", player:getMark("tongyuan1") > 0 and "tongyuan_all" or "tongyuan2")
    end
  end,
})

tongyuan:addEffect(fk.CardRespondFinished, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(tongyuan.name) and data.card.color == Card.Red then
      if data.card.type == Card.TypeTrick then
        return player:getMark("tongyuan1") == 0
      elseif data.card.type == Card.TypeBasic then
        return player:getMark("tongyuan2") == 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.type == Card.TypeTrick then
      room:setPlayerMark(player, "tongyuan1", 1)
      room:setPlayerMark(player, "@tongyuan", player:getMark("tongyuan2") > 0 and "tongyuan_all" or "tongyuan1")
    else
      room:setPlayerMark(player, "tongyuan2", 1)
      room:setPlayerMark(player, "@tongyuan", player:getMark("tongyuan1") > 0 and "tongyuan_all" or "tongyuan2")
    end
  end,
})

tongyuan:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:getMark("tongyuan1") ~= 0 and player:getMark("tongyuan2") ~= 0 and data.card.color == Card.Red then
      return data.card:isCommonTrick()
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(tongyuan.name)
    if event == fk.CardUsing then
      data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
    else
      local targets = room:getUseExtraTargets(data)
      if #targets == 0 then return false end
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#tongyuan-choose:::"..data.card:toLogString(),
        skill_name = tongyuan.name,
        cancelable = true
      })
      if #tos > 0 then
        table.forEach(tos, function (id)
          table.insert(data.tos, {id})
        end)
      end
    end
  end,
})

tongyuan:addEffect(fk.AfterCardTargetDeclared, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:getMark("tongyuan1") ~= 0 and player:getMark("tongyuan2") ~= 0 and data.card.color == Card.Red then
      return data.card.type == Card.TypeBasic and #player.room:getUseExtraTargets(data) > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(tongyuan.name)
    if event == fk.CardUsing then
      data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
    else
      local targets = room:getUseExtraTargets(data)
      if #targets == 0 then return false end
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#tongyuan-choose:::"..data.card:toLogString(),
        skill_name = tongyuan.name,
        cancelable = true
      })
      if #tos > 0 then
        table.forEach(tos, function (id)
          table.insert(data.tos, {id})
        end)
      end
    end
  end,
})

return tongyuan
