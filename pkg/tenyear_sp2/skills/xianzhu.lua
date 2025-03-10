local xianzhu = fk.CreateSkill {
  name = "xianzhu"
}

Fk:loadTranslationTable{
  ['xianzhu'] = '陷筑',
  ['xianzhu1'] = '无视距离和防具',
  ['xianzhu2'] = '可指定目标+1',
  ['xianzhu3'] = '造成伤害后弃牌数+1',
  ['#xianzhu-choice'] = '陷筑：选择【大攻车】使用【杀】的增益效果',
  [':xianzhu'] = '当你使用【杀】造成伤害后，你可以升级【大攻车】（每个【大攻车】最多升级5次）。升级选项：<br>【大攻车】的【杀】无视距离和防具；<br>【大攻车】的【杀】可指定目标+1；<br>【大攻车】的【杀】造成伤害后弃牌数+1。',
  ['$xianzhu1'] = '敌垒已陷，当长驱直入！',
  ['$xianzhu2'] = '舍命陷登，击蛟蟒于狂澜！',
}

xianzhu:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xianzhu.name) and data.card and data.card.trueName == "slash" and
      table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "siege_engine" end) and
      (player:getMark("xianzhu1") + player:getMark("xianzhu2") + player:getMark("xianzhu3")) < 5
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local choices = {"xianzhu2", "xianzhu3"}
    if player:getMark("xianzhu1") == 0 then
      table.insert(choices, 1, "xianzhu1")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = xianzhu.name,
      prompt = "#xianzhu-choice"
    })
    room:addPlayerMark(player, choice, 1)
  end,
})

return xianzhu
