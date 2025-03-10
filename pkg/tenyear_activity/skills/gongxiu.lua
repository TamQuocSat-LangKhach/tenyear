local gongxiu = fk.CreateSkill {
  name = "gongxiu"
}

Fk:loadTranslationTable{
  ['gongxiu'] = '共修',
  ['jinghe'] = '经合',
  ['gongxiu_draw'] = '令“经合”角色各摸一张牌',
  ['gongxiu_discard'] = '令非“经合”角色各弃置一张手牌',
  ['#gongxiu-invoke'] = '共修：你可以执行一项',
  [':gongxiu'] = '结束阶段，若你本回合发动过〖经合〗，你可以选择一项：1.令所有本回合因〖经合〗获得过技能的角色摸一张牌；2.令所有本回合未因〖经合〗获得过技能的其他角色弃置一张手牌。',
  ['$gongxiu1'] = '福祸与共，业山可移。',
  ['$gongxiu2'] = '修行退智，遂之道也。',
}

gongxiu:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(gongxiu.name) and player.phase == Player.Finish and
      player:usedSkillTimes("jinghe", Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player)
    local choices = {"Cancel"}
    local all_choices = {"gongxiu_draw", "gongxiu_discard", "Cancel"}
    if table.find(player.room.alive_players, function(p) return p:getMark("jinghe-turn") == 0 and not p:isKongcheng() end) then
      table.insert(choices, "gongxiu_discard")
    end
    if table.find(player.room.alive_players, function(p) return p:getMark("jinghe-turn") ~= 0 end) then
      table.insert(choices, "gongxiu_draw")
    end
    local choice = player.room:askToChoice(player, {
      choices = choices,
      skill_name = gongxiu.name,
      prompt = "#gongxiu-invoke",
      all_choices = all_choices
    })
    if choice ~= "Cancel" then
      event:setCostData(self, choice)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if event:getCostData(self)[10] == "r" then
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:getMark("jinghe-turn") ~= 0 and not p.dead then
          room:doIndicate(player.id, {p.id})
          p:drawCards(1, gongxiu.name)
        end
      end
    else
      for _, p in ipairs(room:getAlivePlayers()) do
        if p:getMark("jinghe-turn") == 0 and not p.dead then
          room:doIndicate(player.id, {p.id})
          if not p:isKongcheng() then
            room:askToDiscard(p, {
              min_num = 1,
              max_num = 1,
              include_equip = false,
              skill_name = gongxiu.name,
              cancelable = false
            })
          end
        end
      end
    end
  end,
})

return gongxiu
