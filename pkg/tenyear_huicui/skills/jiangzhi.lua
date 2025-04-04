local jiangzhi = fk.CreateSkill {
  name = "jiangzhi",
}

Fk:loadTranslationTable{
  ["jiangzhi"] = "绛脂",
  [":jiangzhi"] = "当你成为基本牌或普通锦囊牌的目标后，若你不是唯一目标，你可以判定，若结果为：红色，你摸三张牌；黑色，"..
  "你可以弃置一名其他角色至多两张牌。",

  ["#jiangzhi-discard"] = "绛脂：你可以弃置一名其他角色至多两张牌",

  ["$jiangzhi1"] = "肌如凝脂，宛若晨露微沾之蕊。",
  ["$jiangzhi2"] = "镜中容颜，肤白胜雪，可胜瑶池仙子否？"
}

jiangzhi:addEffect(fk.TargetConfirmed, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiangzhi.name) and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      not data:isOnlyTarget(player)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = jiangzhi.name,
      pattern = ".|.|^nosuit",
    }
    room:judge(judge)
    if player.dead then return end
    if judge.card.color == Card.Red then
      player:drawCards(3, jiangzhi.name)
    elseif judge.card.color == Card.Black then
      local targets = table.filter(room.alive_players, function(p)
        return p ~= player and not p:isNude()
      end)
      if #targets == 0 then return end
      targets = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#jiangzhi-discard",
        skill_name = jiangzhi.name,
        cancelable = true,
      })
      if #targets > 0 then
        local to = targets[1]
        local cards = room:askToChooseCards(player, {
          target = to,
          min = 1,
          max = 2,
          flag = "he",
          skill_name = jiangzhi.name
        })
        room:throwCard(cards, jiangzhi.name, to, player)
      end
    end
  end,
})

return jiangzhi
