local gonghu = fk.CreateSkill {
  name = "gonghu"
}

Fk:loadTranslationTable{
  ['gonghu'] = '共护',
  ['gonghu1'] = '限两次',
  ['gonghu2'] = '不用给牌',
  ['@gonghu'] = '共护',
  ['gonghu_all'] = '全部生效',
  ['#gonghu_delay'] = '共护',
  ['#gonghu-choose'] = '共护：可为此【%arg】额外指定一个目标',
  [':gonghu'] = '锁定技，当你于回合外一回合失去超过一张基本牌后，〖破锐〗改为“每轮限两次”；当你于回合外一回合造成或受到伤害超过1点伤害后，你删除〖破锐〗中交给牌的效果。若以上两个效果均已触发，则你本局游戏使用红色基本牌无法响应，使用红色普通锦囊牌可以额外指定一个目标。',
  ['$gonghu1'] = '大都督中伏，吾等当舍命救之。',
  ['$gonghu2'] = '袍泽临难，但有共死而无坐视。',
}

gonghu:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(gonghu.name) or player.phase ~= Player.NotActive then return false end
    if player ~= target or player:getMark("gonghu2") > 0 then return false end
    local data = event.data[5]
    if data and data.damage > 1 then return true end

    local x = 0
    player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
      local damage = e.data[5]
      if damage and damage.to == player.id then
        x = x + damage.damage
      end
    end, Player.HistoryTurn)

    return x > 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "gonghu2", 1)
    room:setPlayerMark(player, "@gonghu", player:getMark("gonghu1") > 0 and "gonghu_all" or "gonghu2")
  end,
})

gonghu:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(gonghu.name) or player.phase ~= Player.NotActive then return false end
    if player:getMark("gonghu2") > 0 then return false end

    local data = event.data[5]
    if data and data.damage > 1 then return true end

    local x = 0
    player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function (e)
      local damage = e.data[5]
      if damage and damage.from == player.id then
        x = x + damage.damage
      end
    end, Player.HistoryTurn)

    return x > 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "gonghu2", 1)
    room:setPlayerMark(player, "@gonghu", player:getMark("gonghu1") > 0 and "gonghu_all" or "gonghu2")
  end,
})

gonghu:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(gonghu.name) or player.phase ~= Player.NotActive then return false end
    if player:getMark("gonghu1") > 0 then return false end

    local x = 0
    for _, move in ipairs(event.data) do
      if move.from == player.id and (move.to ~= player.id or 
        (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
        for _, info in ipairs(move.moveInfo) do
          if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
            Fk:getCardById(info.cardId).type == Card.TypeBasic then
            x = x + 1
          end
        end
      end
    end

    if x ~= 1 then return false end

    player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
      for _, move in ipairs(e.data) do
        if move.from == player.id and (move.to ~= player.id or 
          (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
          for _, info in ipairs(move.moveInfo) do
            if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
              Fk:getCardById(info.cardId).type == Card.TypeBasic then
              x = x + 1
            end
          end
        end
      end
    end, Player.HistoryTurn)

    return x > 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "gonghu1", 1)
    room:setPlayerMark(player, "@gonghu", player:getMark("gonghu2") > 0 and "gonghu_all" or "gonghu1")
  end,
})

local gonghu_delay = fk.CreateTriggerSkill{
  name = "#gonghu_delay",
  frequency = Skill.Compulsory,
  events = {fk.CardUsing, fk.AfterCardTargetDeclared},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:getMark("gonghu1") ~= 0 and player:getMark("gonghu2") ~=0 and data.card.color == Card.Red then
      if event == fk.CardUsing then
        return data.card.type == Card.TypeBasic
      else
        return data.card:isCommonTrick() and #player.room:getUseExtraTargets(data) > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(gonghu.name)
    if event == fk.CardUsing then
      data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
    else
      local targets = room:getUseExtraTargets(data)
      if #targets == 0 then return false end
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#gonghu-choose:::"..data.card:toLogString(),
        skill_name = gonghu.name,
        cancelable = true
      })
      if #tos > 0 then
        table.forEach(tos, function (id)
          table.insert(data.tos, {id})
        end)
      end
    end
  end,
}

return gonghu
