local xiaoxi = fk.CreateSkill {
  name = "xiaoxi"
}

Fk:loadTranslationTable{
  ['xiaoxi'] = '宵袭',
  ['#xiaoxi1-choice'] = '宵袭：你需减少1或2点体力上限',
  ['#xiaoxi-choose'] = '宵袭：选择攻击范围内一名角色，获得其等量牌或视为对其使用等量【杀】',
  ['xiaoxi_prey'] = '获得其X张牌',
  ['xiaoxi_slash'] = '视为对其使用X张【杀】',
  ['#xiaoxi2-choice'] = '宵袭：选择对 %dest 执行的一项（X为%arg）',
  [':xiaoxi'] = '锁定技，出牌阶段开始时，你需减少1或2点体力上限，然后选择一项：1.获得你攻击范围内一名其他角色等量的牌；2.视为对你攻击范围内的一名其他角色使用等量张【杀】。',
  ['$xiaoxi1'] = '夜深枭啼，亡命夺袭！',
  ['$xiaoxi2'] = '以夜为幕，纵兵逞凶！',
}

xiaoxi:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"1", "2"}
    if player.maxHp == 1 then
      choices = {"1"}
    end
    local n = tonumber(room:askToChoice(player, {
      choices = choices,
      skill_name = xiaoxi.name,
      prompt = "#xiaoxi1-choice"
    }))
    room:changeMaxHp(player, -n)
    if player.dead then return end
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return player:inMyAttackRange(p) 
    end), Util.IdMapper)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#xiaoxi-choose",
      skill_name = xiaoxi.name
    })
    if #to > 0 then
      to = room:getPlayerById(to[1])
    else
      to = room:getPlayerById(table.random(targets))
    end
    choices = {"xiaoxi_prey", "xiaoxi_slash"}
    if #to:getCardIds{Player.Hand, Player.Equip} < n then
      choices = {"xiaoxix_slash"}
    elseif player:isProhibited(to, Fk:cloneCard("slash")) then
      choices = {"xiaoxi_prey"}
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = xiaoxi.name,
      prompt = "#xiaoxi2-choice::"..to.id..":"..n
    })
    if choice == "xiaoxi_prey" then
      local cards = room:askToChooseCards(player, {
        target = to,
        min = n,
        max = n,
        flag = "he",
        reason = xiaoxi.name
      })
      room:obtainCard(player, cards, false, fk.ReasonPrey)
    else
      for i = 1, n, 1 do
        if player.dead or to.dead then return end
        room:useVirtualCard("slash", nil, player, to, xiaoxi.name, true)
      end
    end
  end,
})

return xiaoxi
