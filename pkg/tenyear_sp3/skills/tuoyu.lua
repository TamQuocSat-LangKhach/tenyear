local tuoyu = fk.CreateSkill {
  name = "tuoyu"
}

Fk:loadTranslationTable{
  ['tuoyu'] = '拓域',
  ['tuoyu1'] = '丰田',
  ['tuoyu2'] = '清渠',
  ['tuoyu3'] = '峻山',
  ['@@tuoyu1-inhand'] = '丰田',
  ['@@tuoyu2-inhand'] = '清渠',
  ['@@tuoyu3-inhand'] = '峻山',
  [':tuoyu'] = '锁定技，你的手牌区域添加三个未开发的副区域：<br>丰田：伤害和回复值+1；<br>清渠：无距离和次数限制；<br>峻山：不能被响应。<br>出牌阶段开始时和结束时，你将手牌分配至已开发的副区域中，每个区域至多五张。',
  ['$tuoyu1'] = '本尊目之所及，皆为麾下王土。',
  ['$tuoyu2'] = '擎五丁之神力，碎万仞之高山。',
}

tuoyu:addEffect(fk.EventPhaseStart, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tuoyu.name) and player.phase == Player.Play and not player:isKongcheng() and
      table.find({"1", "2", "3"}, function(n) return player:getMark("tuoyu"..n) > 0 end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player.player_cards[Player.Hand]
    local markedcards = {{}, {}, {}}
    local card
    for _, id in ipairs(cards) do
      card = Fk:getCardById(id)
      for i = 1, 3, 1 do
        if card:getMark("@@tuoyu" .. tostring(i) .. "-inhand") > 0 then
          table.insert(markedcards[i], id)
          break
        end
      end
    end
    local result = room:askToCustomDialog(player, {
      skill_name = tuoyu.name,
      qml_path = "packages/tenyear/qml/TuoyuBox.qml",
      extra_data = {
        cards,
        markedcards[1], player:getMark("tuoyu1") > 0,
        markedcards[2], player:getMark("tuoyu2") > 0,
        markedcards[3], player:getMark("tuoyu3") > 0,
      }
    })
    if result ~= "" then
      local d = json.decode(result)
      for _, id in ipairs(cards) do
        card = Fk:getCardById(id)
        for i = 1, 3, 1 do
          room:setCardMark(card, "@@tuoyu"..i .. "-inhand", table.contains(d[i], id) and 1 or 0)
        end
      end
    end
  end,
})

tuoyu:addEffect(fk.EventPhaseEnd, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tuoyu.name) and player.phase == Player.Play and not player:isKongcheng() and
      table.find({"1", "2", "3"}, function(n) return player:getMark("tuoyu"..n) > 0 end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player.player_cards[Player.Hand]
    local markedcards = {{}, {}, {}}
    local card
    for _, id in ipairs(cards) do
      card = Fk:getCardById(id)
      for i = 1, 3, 1 do
        if card:getMark("@@tuoyu" .. tostring(i) .. "-inhand") > 0 then
          table.insert(markedcards[i], id)
          break
        end
      end
    end
    local result = room:askToCustomDialog(player, {
      skill_name = tuoyu.name,
      qml_path = "packages/tenyear/qml/TuoyuBox.qml",
      extra_data = {
        cards,
        markedcards[1], player:getMark("tuoyu1") > 0,
        markedcards[2], player:getMark("tuoyu2") > 0,
        markedcards[3], player:getMark("tuoyu3") > 0,
      }
    })
    if result ~= "" then
      local d = json.decode(result)
      for _, id in ipairs(cards) do
        card = Fk:getCardById(id)
        for i = 1, 3, 1 do
          room:setCardMark(card, "@@tuoyu"..i .. "-inhand", table.contains(d[i], id) and 1 or 0)
        end
      end
    end
  end,
})

tuoyu:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card)
    return card and player:hasSkill(tuoyu.name) and card:getMark("@@tuoyu2-inhand") > 0
  end,
  bypass_distances =  function(self, player, skill, card)
    return card and player:hasSkill(tuoyu.name) and card:getMark("@@tuoyu2-inhand") > 0
  end,
})

tuoyu:addEffect(fk.PreCardUse, {
  global = false,
  can_refresh = function(self, event, target, player, data)
    return target == player and not data.card:isVirtual() and player:hasSkill(tuoyu.name) and
      (data.card:getMark("@@tuoyu1-inhand") > 0 or data.card:getMark("@@tuoyu2-inhand") > 0 or data.card:getMark("@@tuoyu3-inhand") > 0)
  end,
  on_refresh = function(self, event, target, player, data)
    if data.card:getMark("@@tuoyu1-inhand") > 0 then
      if data.card.name == "analeptic" then
        if data.extra_data and data.extra_data.analepticRecover then
          data.additionalRecover = (data.additionalRecover or 0) + 1
        else
          data.extra_data = data.extra_data or {}
          data.extra_data.additionalDrank = (data.extra_data.additionalDrank or 0) + 1
        end
      else
        data.additionalDamage = (data.additionalDamage or 0) + 1
        data.additionalRecover = (data.additionalRecover or 0) + 1
      end
    elseif data.card:getMark("@@tuoyu2-inhand") > 0 then
      data.extraUse = true
    elseif data.card:getMark("@@tuoyu3-inhand") > 0 then
      data.disresponsiveList = table.map(player.room.alive_players, Util.IdMapper)
    end
  end,
})

return tuoyu
