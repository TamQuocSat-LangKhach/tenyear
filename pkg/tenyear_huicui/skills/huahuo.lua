local huahuo = fk.CreateSkill {
  name = "huahuo"
}

Fk:loadTranslationTable{
  ['huahuo'] = '花火',
  ['#huahuo'] = '花火：你可以将一张红色手牌当不计次的火【杀】使用，目标可以改为所有有“硝引”的角色',
  ['xiaoyin'] = '硝引',
  ['#huahuo-invoke'] = '花火：是否将目标改为所有有“硝引”的角色？',
  [':huahuo'] = '出牌阶段限一次，你可以将一张红色手牌当无次数限制的【杀】使用。若目标有“硝引”牌，此【杀】可改为指定所有有“硝引”牌的角色为目标。',
  ['$huahuo1'] = '馏石漆取上清，可为胜爆竹之花火。',
  ['$huahuo2'] = '莫道繁花好颜色，此火犹胜二月黄。',
}

huahuo:addEffect('viewas', {
  anim_type = "offensive",
  prompt = "#" .. huahuo.name,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("fire__slash")
    card.skillName = huahuo.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function(self, player, use)
    use.extraUse = true
    local room = player.room
    local tos = TargetGroup:getRealTargets(use.tos)
    if table.find(tos, function(id) return #room:getPlayerById(id):getPile("xiaoyin") > 0 end) and
      table.find(room:getOtherPlayers(player), function(p) return not table.contains(tos, p.id) and #p:getPile("xiaoyin") > 0 end) then
      if room:askToSkillInvoke(player, { skill_name = huahuo.name, prompt = "#huahuo-invoke" }) then
        for _, p in ipairs(room:getOtherPlayers(player)) do
          if not table.contains(tos, p.id) and #p:getPile("xiaoyin") > 0 and not player:isProhibited(p, use.card) then
            TargetGroup:pushTargets(use.tos, p.id)
          end
        end
      end
    end
  end,
  enabled_at_play = function (self, player)
    return player:usedSkillTimes(huahuo.name, Player.HistoryPhase) == 0
  end,
})

huahuo:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, huahuo.name)
  end,
})

return huahuo
