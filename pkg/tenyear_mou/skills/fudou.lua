local fudou = fk.CreateSkill {
  name = "fudou",
}

Fk:loadTranslationTable{
  ["fudou"] = "覆斗",
  [":fudou"] = "当你使用黑色牌指定其他角色为唯一目标后，若其本局游戏对你造成过伤害，你可以与其各失去1点体力；"..
  "当你使用红色牌指定其他角色为唯一目标后，若其本局游戏没对你造成过伤害，你可以与其各摸一张牌。",

  ["#fanshi1-invoke"] = "覆斗：是否与 %dest 各失去1点体力？",
  ["#fanshi2-invoke"] = "覆斗：是否与 %dest 各摸一张牌？",

  ["$fudou1"] = "既作困禽，何妨铤险以覆车？",
  ["$fudou2"] = "据将覆之巢，必作犹斗之困兽。",
}

fudou:addEffect(fk.TargetSpecified, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(fudou.name) and data.to ~= player and
      data:isOnlyTarget(data.to) and data.card.color ~= Card.NoColor then
      local mark = player:getTableMark("fudou_record")
      if table.contains(mark, data.to.id) then
        return data.card.color == Card.Black
      else
        if #player.room.logic:getActualDamageEvents(1, function (e)
          local damage = e.data
          return damage.from == data.to and damage.to == player
        end, Player.HistoryGame) > 0 then
          table.insert(mark, data.to.id)
          player.room:setPlayerMark(player, "fudou_record", mark)
          return data.card.color == Card.Black
        else
          return data.card.color == Card.Red
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local prompt = data.card.color == Card.Black and "#fanshi1-invoke::"..data.to.id or "#fanshi2-invoke::"..data.to.id
    if room:askToSkillInvoke(player, {
      skill_name = fudou.name,
      prompt = prompt,
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.color == Card.Red then
      player:drawCards(1, fudou.name)
      if not data.to.dead then
        data.to:drawCards(1, fudou.name)
      end
    elseif data.card.color == Card.Black then
      room:loseHp(player, 1, fudou.name)
      if not data.to.dead then
        room:loseHp(data.to, 1, fudou.name)
      end
    end
  end,
})

return fudou
