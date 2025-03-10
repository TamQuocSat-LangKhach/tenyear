local fudou = fk.CreateSkill {
  name = "fudou"
}

Fk:loadTranslationTable{
  ['fudou'] = '覆斗',
  ['#fanshi-invoke'] = '是否发动 覆斗，与%dest各 %arg',
  [':fudou'] = '当你使用黑色/红色牌指定其他角色为唯一目标后，若其对你造成过伤害/没有对你造成过伤害，你可以与其各失去1点体力/摸一张牌。',
  ['$fudou1'] = '既作困禽，何妨铤险以覆车？',
  ['$fudou2'] = '据将覆之巢，必作犹斗之困兽。',
}

fudou:addEffect(fk.TargetSpecified, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(fudou.name) or player ~= target or data.to == player.id then return false end
    local room = player.room
    local to = room:getPlayerById(data.to)
    if to.dead or not U.isOnlyTarget(to, data, event) then return false end
    local mark = player:getTableMark("fudou_record")
    if table.contains(mark, data.to) then
      return data.card.color == Card.Black
    else
      if #room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data[1]
        if damage.from == to and damage.to == player then
          return true
        end
      end, nil, 0) > 0 then
        table.insert(mark, data.to)
        room:setPlayerMark(player, "fudou_record", mark)
        return data.card.color == Card.Black
      else
        return data.card.color == Card.Red
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local opinion = data.card.color == Card.Black and "loseHp" or "draw1"
    if room:askToSkillInvoke(player, {
      skill_name = fudou.name,
      prompt = "#fanshi-invoke::"..data.to .. ":" .. opinion
    }) then
      room:doIndicate(player.id, {data.to})
      event:setCostData(self, true)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(fudou.name)
    local to = room:getPlayerById(data.to)
    if data.card.color == Card.Red then
      room:notifySkillInvoked(player, fudou.name, "support")
      player:drawCards(1, fudou.name)
      if not to.dead then
        to:drawCards(1, fudou.name)
      end
    elseif data.card.color == Card.Black then
      room:notifySkillInvoked(player, fudou.name, "offensive")
      room:loseHp(player, 1, fudou.name)
      if not to.dead then
        room:loseHp(to, 1, fudou.name)
      end
    end
  end,
})

return fudou
