local xianwei = fk.CreateSkill {
  name = "xianwei"
}

Fk:loadTranslationTable{
  ['xianwei'] = '险卫',
  ['#xianwei-abort'] = '险卫：废除一个装备栏',
  ['#xianwei-choose'] = '险卫：令一名角色使用牌堆中一张%arg',
  ['@@xianwei'] = '险卫',
  [':xianwei'] = '锁定技，准备阶段，你废除一个装备栏并摸等同于你未废除装备栏数的牌，然后令一名其他角色使用牌堆中第一张此副类别的装备牌（没有则其摸一张牌）。<br>你的所有装备栏均废除后，你加2点体力上限，然后你和其他角色始终互相视为在对方攻击范围内。',
  ['$xianwei1'] = '曹家儿郎，何惧一死！',
  ['$xianwei2'] = '此役当战，有死无生！',
}

xianwei:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Start and #player:getAvailableEquipSlots() > 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local choices = player:getAvailableEquipSlots()
    local choice = room:askToChoice(player, {choices = choices, skill_name = skill.name, prompt = "#xianwei-abort"})
    room:abortPlayerArea(player, choice)
    if player.dead then return end
    if #player:getAvailableEquipSlots() > 0 then
      player:drawCards(#player:getAvailableEquipSlots(), skill.name)
    end
    if player.dead then return end
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    local mapper = {
      [Player.WeaponSlot] = "weapon",
      [Player.ArmorSlot] = "armor",
      [Player.OffensiveRideSlot] = "offensive_horse",
      [Player.DefensiveRideSlot] = "defensive_horse",
      [Player.TreasureSlot] = "treasure",
    }
    local to = room:askToChoosePlayers(player, {targets = targets, min_num = 1, max_num = 1, prompt = "#xianwei-choose:::"..mapper[choice], skill_name = skill.name})
    if #to > 0 then
      to = to[1]
    else
      to = table.random(targets)
    end
    to = room:getPlayerById(to)
    local subtype = Util.convertSubtypeAndEquipSlot(choice)
    for _, id in ipairs(room.draw_pile) do
      local card = Fk:getCardById(id)
      if card.sub_type == subtype and not to:isProhibited(to, card) then
        room:useCard({
          from = to.id,
          tos = {{to.id}},
          card = card,
        })
        return
      end
    end
    to:drawCards(1, skill.name)
  end,
})

xianwei:addEffect(fk.AreaAborted, {
  anim_type = "support",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(skill.name) and #player:getAvailableEquipSlots() == 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "@@xianwei", 1)
    room:changeMaxHp(player, 2)
  end,
})

local xianwei_attackrange = fk.CreateAttackRangeSkill{
  name = "#xianwei_attackrange",
  frequency = Skill.Compulsory,
  within_func = function (self, from, to)
    return from:getMark("@@xianwei") > 0 or to:getMark("@@xianwei") > 0
  end,
}

return xianwei
