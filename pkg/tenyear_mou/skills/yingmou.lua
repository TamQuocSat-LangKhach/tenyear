local yingmou = fk.CreateSkill {
  name = "yingmou"
}

Fk:loadTranslationTable{
  ['yingmou'] = '英谋',
  ['#yingmou_yang-invoke'] = '英谋：选择一名角色，你将手牌补至与其相同，然后视为对其使用【火攻】',
  ['#yingmou_yin-invoke'] = '英谋：选择一名角色，然后令手牌最多的角色对其使用手牌中所有【杀】和伤害锦囊牌',
  ['#yingmou-choose'] = '英谋：选择手牌数最多的一名角色，其对 %dest 使用手牌中所有【杀】和伤害锦囊牌',
  ['#yingmou_switch'] = '英谋',
  [':yingmou'] = '转换技，游戏开始时可自选阴阳状态，每回合限一次，当你对其他角色使用牌结算后，你可以选择其中一个目标角色，阳：你将手牌摸至与其相同（至多摸五张），然后视为对其使用一张【火攻】；阴：令一名手牌最多的角色对其使用手牌中所有【杀】和伤害锦囊牌，若没有则将手牌弃至与你相同。',
  ['$yingmou1'] = '行计以险，纵略以奇，敌虽百万亦戏之如犬豕。',
  ['$yingmou2'] = '若生铸剑为犁之心，须有纵钺止戈之力。',
}

yingmou:addEffect(fk.CardUseFinished, {
  anim_type = "switch",
  switch_skill_name = "yingmou",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yingmou) and data.tos and
      table.find(TargetGroup:getRealTargets(data.tos), function(id) return id ~= player.id and not player.room:getPlayerById(id).dead end) and
      player:usedSkillTimes(yingmou.name, Player.HistoryTurn) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(TargetGroup:getRealTargets(data.tos), function(id) return not room:getPlayerById(id).dead end)
    local prompt
    if player:getSwitchSkillState(yingmou.name, false) == fk.SwitchYang then
      prompt = "#yingmou_yang-invoke"
    elseif player:getSwitchSkillState(yingmou.name, false) == fk.SwitchYin then
      prompt = "#yingmou_yin-invoke"
    end
    local to = room:askToChoosePlayers(player, {
      targets = Util.IdMapper(targets),
      min_num = 1,
      max_num = 1,
      skill_name = yingmou.name,
      cancelable = true,
      prompt = prompt,
    })
    if #to > 0 then
      event:setCostData(self, to[1].id)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    setTYMouSwitchSkillState(player, "zhouyu", yingmou.name)
    local to = room:getPlayerById(event:getCostData(self))
    if player:getSwitchSkillState(yingmou.name, true) == fk.SwitchYang then
      if player:getHandcardNum() < to:getHandcardNum() then
        player:drawCards(math.min(to:getHandcardNum() - player:getHandcardNum(), 5), yingmou.name)
      end
      if not player.dead and not to.dead and not to:isKongcheng() then
        room:useVirtualCard("fire_attack", nil, player, to, yingmou.name)
      end
    elseif player:getSwitchSkillState(yingmou.name, true) == fk.SwitchYin then
      local targets = table.map(table.filter(room.alive_players, function(p)
        return table.every(room.alive_players, function(p2)
          return p:getHandcardNum() >= p2:getHandcardNum()
        end)
      end), Util.IdMapper)
      if room:getPlayerById(targets[1]):getHandcardNum() == 0 then return end
      local src
      if #targets == 1 then
        src = targets[1]
      else
        src = room:askToChoosePlayers(player, {
          targets = Util.IdMapper(targets),
          min_num = 1,
          max_num = 1,
          skill_name = yingmou.name,
          cancelable = false,
          no_indicate = true,
          prompt = "#yingmou-choose::" .. to.id
        })[1].id
      end
      src = room:getPlayerById(src)
      local cards = table.filter(src:getCardIds("h"), function(id) return Fk:getCardById(id).is_damage_card end)
      if #cards > 0 then
        cards = table.reverse(cards)
        for i = #cards, 1, -1 do
          if src.dead or to.dead or to:isKongcheng() then
            break
          end
          if table.contains(src:getCardIds("h"), cards[i]) then
            local card = Fk:getCardById(cards[i])
            if src:canUseTo(card, to, { bypass_distances = true, bypass_times = true}) then
              room:useCard({
                from = src.id,
                tos = {{to.id}},
                card = card,
                extraUse = true,
              })
            end
          end
        end
      else
        local n = src:getHandcardNum() - player:getHandcardNum()
        if n > 0 then
          room:askToDiscard(src, {
            min_num = n,
            max_num = n,
            include_equip = false,
            skill_name = yingmou.name,
            cancelable = false
          })
        end
      end
    end
  end,
})

yingmou:addEffect(fk.GameStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(yingmou)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    setTYMouSwitchSkillState(player, "zhouyu", yingmou.name,
      player.room:askToChoice(player, {
        choices = { "tymou_switch:::yingmou:yang", "tymou_switch:::yingmou:yin" },
        skill_name = "yingmou",
        prompt = "#tymou_switch-transer:::yingmou"
      }) == "tymou_switch:::yingmou:yin")
  end,
})

return yingmou
