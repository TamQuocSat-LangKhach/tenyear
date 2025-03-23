local lianjie = fk.CreateSkill {
  name = "lianjie"
}

Fk:loadTranslationTable{
  ['lianjie'] = '连捷',
  ['@@lianjie-inhand-turn'] = '连捷',
  [':lianjie'] = '当你使用手牌指定目标后，若你手牌的点数均不小于此牌点数（每个点数每回合限一次，无点数视为0），你可以将手牌摸至体力上限，本回合使用以此法摸到的牌无距离次数限制。',
}

lianjie:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and data.firstTarget and player:getHandcardNum() < player.maxHp and
      U.IsUsingHandcard(player, data) and not player:isKongcheng() and
      table.every(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).number >= data.card.number
      end) and
      not table.contains(player:getTableMark("lianjie-turn"), data.card.number)
  end,
  on_use = function(self, event, target, player, data)
    player.room:addTableMark(player, "lianjie-turn", data.card.number)
    local params = {
      min_num = player.maxHp - player:getHandcardNum(),
      max_num = player.maxHp - player:getHandcardNum(),
      skill_name = lianjie.name,
      prompt = "@@lianjie-inhand-turn",
    }
    player:askToDrawCards(player, params)
  end,
})

local lianjie_targetmod = fk.CreateSkill {
  name = "#lianjie_targetmod"
}

lianjie_targetmod:addEffect('targetmod', {
  bypass_times = function(self, player, skill_name, scope, card, to)
    return card and card:getMark("@@lianjie-inhand-turn") > 0
  end,
  bypass_distances = function(self, player, skill_name, card)
    return card and card:getMark("@@lianjie-inhand-turn") > 0
  end,
})

return lianjie
