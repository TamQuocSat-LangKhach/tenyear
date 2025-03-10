local jiaohao = fk.CreateSkill {
  name = "ty__jiaohao"
}

Fk:loadTranslationTable{
  ['ty__jiaohao'] = '骄豪',
  ['#ty__jiaohao-active'] = '发动 骄豪，与装备区里的牌数不大于你的角色拼点',
  ['ty__jiaohao_slash'] = '令其可以使用一张【杀】',
  ['ty__jiaohao_obtain'] = '令其获得拼点的牌',
  ['#ty__jiaohao-choice'] = '骄豪：你可以选择一项令%dest执行',
  ['#ty__jiaohao-slash'] = '骄豪：你可以使用一张【杀】',
  [':ty__jiaohao'] = '出牌阶段限一次，你可以与装备区里的牌数不大于你的角色拼点，然后你可以令拼点赢的角色获得拼点的牌或者令其使用一张【杀】。',
  ['$ty__jiaohao1'] = '身虽为碧玉，手不怠锟铻！',
  ['$ty__jiaohao2'] = '站住！且与本姑娘分个高下！'
}

jiaohao:addEffect('active', {
  anim_type = "control",
  prompt = "#ty__jiaohao-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(jiaohao.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= player.id then
      local target = Fk:currentRoom():getPlayerById(to_select)
      return player:canPindian(target) and #player:getCardIds(Player.Equip) >= #target:getCardIds(Player.Equip)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, jiaohao.name)
    if player.dead then return end
    local winner = pindian.results[target.id].winner
    if winner == nil or winner.dead then return end
    local cards = {}
    local id = pindian.fromCard:getEffectiveId()
    if room:getCardArea(id) == Card.DiscardPile then
      table.insert(cards, id)
    end
    id = pindian.results[target.id].toCard:getEffectiveId()
    if room:getCardArea(id) == Card.DiscardPile then
      table.insertIfNeed(cards, id)
    end
    local choices = {"ty__jiaohao_slash", "Cancel"}
    if #cards > 0 then
      table.insert(choices, "ty__jiaohao_obtain")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = jiaohao.name,
      prompt = "#ty__jiaohao-choice::" .. winner.id,
      cancelable = false,
    })
    if choice == "ty__jiaohao_obtain" then
      room:obtainCard(winner, cards, true, fk.ReasonJustMove, winner.id, jiaohao.name)
    elseif choice == "ty__jiaohao_slash" then
      local use = room:askToUseCard(winner, {
        pattern = "slash",
        skill_name = "#ty__jiaohao-slash",
        cancelable = true,
        extra_data = { bypass_times = true }
      })
      if use then
        use.extraUse = true
        room:useCard(use)
      end
    end
  end,
})

return jiaohao
