local kuangzuo = fk.CreateSkill {
  name = "kuangzuo",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["kuangzuo"] = "匡祚",
  [":kuangzuo"] = "限定技，出牌阶段，你可以令一名角色获得技能〖承奉〗（若其为主公且没有主公技，则额外获得〖统荫〗），然后令另一名角色"..
  "将每种花色各一张牌置于获得技能角色的武将牌上（称为“匡祚”牌）。",

  ["#kuangzuo"] = "匡祚：令一名角色获得技能〖承奉〗，若其为主公且没有主公技，则额外获得〖统荫〗",
  ["#kuangzuo-choose"] = "匡祚：令一名角色将其每种花色各一张牌置为 %dest 的“匡祚”牌",
  ["#kuangzuo-ask"] = "匡祚：请将每种花色各一张牌置为 %dest 的“匡祚”牌",

  ["$kuangzuo1"] = "家国兴衰，系于一肩之上，朝纲待重振之时。",
  ["$kuangzuo2"] = "吾辈向汉，当矢志不渝，不可坐视神州陆沉。",
}

kuangzuo:addEffect("active", {
  anim_type = "support",
  prompt = "#kuangzuo",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(kuangzuo.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local skills = {"chengfeng"}
    if target.role == "lord" and not table.find(target:getSkillNameList(), function(s)
      return Fk.skills[s]:hasTag(Skill.Lord)
    end) then
      table.insert(skills, "tongyin")
    end
    room:handleAddLoseSkills(target, skills)
    if player.dead or target.dead then return end
    local targets = table.filter(room:getOtherPlayers(target, false), function (p)
      return not p:isNude()
    end)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      skill_name = kuangzuo.name,
      min_num = 1,
      max_num = 1,
      targets = targets,
      prompt = "#kuangzuo-choose::"..target.id,
      cancelable = false,
    })[1]
    local success, dat = room:askToUseActiveSkill(to, {
      skill_name = "kuangzuo_active",
      prompt = "#kuangzuo-ask::" .. target.id,
      cancelable = false,
    })
    if success and dat then
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
    target:addToPile(kuangzuo.name, dat.cards, true, kuangzuo.name, to)
  end,
})

return kuangzuo
