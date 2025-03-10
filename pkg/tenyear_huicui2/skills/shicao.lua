local shicao = fk.CreateSkill {
  name = "shicao"
}

Fk:loadTranslationTable{
  ['shicao'] = '识草',
  ['#shicao-active'] = '发动 识草，选择牌的类别和摸牌的位置',
  [':shicao'] = '出牌阶段，你可以声明一种类别，从牌堆顶/牌堆底摸一张牌，若此牌不为你声明的类别，你观看牌堆底/牌堆顶的两张牌，此技能于此回合内无效。',
  ['$shicao1'] = '药长于草木，然草木非皆可入药。',
  ['$shicao2'] = '掌中非药，乃活人之根本。',
}

shicao:addEffect('active', {
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  prompt = "#shicao-active",
  can_use = function(self, player)
    return player:usedSkillTimes(shicao.name) < 20
  end,
  interaction = function()
    return UI.ComboBox {choices = {
      "shicao_type:::basic:Top", "shicao_type:::basic:Bottom",
      "shicao_type:::trick:Top", "shicao_type:::trick:Bottom",
      "shicao_type:::equip:Top", "shicao_type:::equip:Bottom",
    } }
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local shicao_type = self.interaction.data:split(":")
    local from_place = shicao_type[5]:lower()
    local ids = room:drawCards(player, 1, shicao.name, from_place)
    if #ids == 0 or player.dead then return end
    if Fk:getCardById(ids[1]):getTypeString() ~= shicao_type[4] then
      if from_place == "top" then
        ids = room:getNCards(2, "bottom")
        table.removeOne(room.draw_pile, ids[1])
        table.removeOne(room.draw_pile, ids[2])
        table.insertTable(room.draw_pile, ids)
      else
        ids = room:getNCards(2)
        table.removeOne(room.draw_pile, ids[1])
        table.removeOne(room.draw_pile, ids[2])
        table.insert(room.draw_pile, 1, ids[2])
        table.insert(room.draw_pile, 1, ids[1])
      end
      U.viewCards(player, ids, shicao.name)
      room:invalidateSkill(player, shicao.name, "-turn")
    end
  end,
})

return shicao
