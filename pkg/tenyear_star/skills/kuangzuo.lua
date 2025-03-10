local kuangzuo = fk.CreateSkill {
  name = "kuangzuo"
}

Fk:loadTranslationTable{
  ['kuangzuo'] = '匡祚',
  ['#kuangzuo'] = '匡祚：令一名角色获得技能〖承奉〗，若其为主公且没有主公技，则额外获得〖统荫〗',
  ['chengfeng'] = '承奉',
  ['tongyin'] = '统荫',
  ['#kuangzuo-choose'] = '匡祚：令一名角色将其每种花色各一张牌置为 %dest 的“匡祚”牌',
  ['kuangzuo_active'] = '匡祚',
  ['#kuangzuo-put'] = '匡祚：请将每种花色各一张牌置为 %dest 的“匡祚”牌',
  [':kuangzuo'] = '限定技，出牌阶段，你可以令一名角色获得技能〖承奉〗（若其为主公且没有主公技，则额外获得〖统荫〗），然后令另一名角色将每种花色各一张牌置于获得技能角色的武将牌上（称为“匡祚”牌）。',
  ['$kuangzuo1'] = '家国兴衰，系于一肩之上，朝纲待重振之时。',
  ['$kuangzuo2'] = '吾辈向汉，当矢志不渝，不可坐视神州陆沉。',
}

kuangzuo:addEffect('active', {
  anim_type = "support",
  frequency = Skill.Limited,
  card_num = 0,
  target_num = 1,
  prompt = "#kuangzuo",
  can_use = function(self, player)
    return player:usedSkillTimes(kuangzuo.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local skills = {"chengfeng"}
    if target.role == "lord" and not table.find(target.player_skills, function(s)
      return s.lordSkill
    end) then
      table.insert(skills, "tongyin")
    end
    room:handleAddLoseSkills(target, skills, nil, true, false)
    if player.dead or target.dead then return end
    local targets = table.filter(room:getOtherPlayers(target), function (p)
      return not p:isNude()
    end)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      targets = table.map(targets, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      skill_name = "#kuangzuo-choose::" .. target.id,
    })
    to = room:getPlayerById(to[1])
    local success, dat = room:askToUseActiveSkill(to, {
      skill_name = "kuangzuo_active",
      prompt = "#kuangzuo-put::" .. target.id,
      cancelable = false
    })
    if success and dat then
      -- handle success case
    else
      dat = {
        cards = {},
      }
      for _, id in ipairs(to:getCardIds("he")) do
        local card = Fk:getCardById(id)
        if card.suit ~= Card.NoSuit and not table.find(dat.cards, function (id2)
          return card:compareSuitWith(Fk:getCardById(id2))
        end) then
          table.insert(dat.cards, id)
        end
      end
    end
    target:addToPile(kuangzuo.name, dat.cards, true, kuangzuo.name, to.id)
  end,
})

return kuangzuo
