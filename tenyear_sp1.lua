local extension = Package("tenyear_sp1")
extension.extensionName = "tenyear"

Fk:loadTranslationTable{
  ["tenyear_sp1"] = "十周年专属1",
  ["ty"] = "新服",
}

local yanjun = General(extension, "yanjun", "wu", 3)
local guanchao = fk.CreateTriggerSkill{
  name = "guanchao",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"@@guanchao_ascending-turn", "@@guanchao_decending-turn"}, self.name)
    room:setPlayerMark(player, choice, 1)
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(self.name, Player.HistoryTurn) > 0 and
      (player:getMark("@@guanchao_ascending-turn") > 0 or player:getMark("@@guanchao_decending-turn") > 0 or
      player:getMark("@guanchao_ascending-turn") > 0 or player:getMark("@guanchao_decending-turn") > 0)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@@guanchao_ascending-turn") > 0 then
      room:setPlayerMark(player, "@@guanchao_ascending-turn", 0)
      if data.card.number then
        room:setPlayerMark(player, "@guanchao_ascending-turn", data.card.number)
      end
    elseif player:getMark("@@guanchao_decending-turn") > 0 then
      room:setPlayerMark(player, "@@guanchao_decending-turn", 0)
      if data.card.number then
        room:setPlayerMark(player, "@guanchao_decending-turn", data.card.number)
      end
    elseif player:getMark("@guanchao_ascending-turn") > 0 then
      if data.card.number and data.card.number > player:getMark("@guanchao_ascending-turn") then
        room:setPlayerMark(player, "@guanchao_ascending-turn", data.card.number)
        player:drawCards(1, self.name)
      else
        room:setPlayerMark(player, "@guanchao_ascending-turn", 0)
      end
    elseif player:getMark("@guanchao_decending-turn") > 0 then
      if data.card.number and data.card.number < player:getMark("@guanchao_decending-turn") then
        room:setPlayerMark(player, "@guanchao_decending-turn", data.card.number)
        player:drawCards(1, self.name)
      else
        room:setPlayerMark(player, "@guanchao_decending-turn", 0)
      end
    end
  end,
}
local xunxian = fk.CreateTriggerSkill{
  name = "xunxian",
  anim_type = "support",
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.NotActive and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and player.room:getCardArea(data.card) == Card.Processing
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return #p.player_cards[Player.Hand] > #player.player_cards[Player.Hand] end), function(p) return p.id end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#xunxian-choose:::"..data.card:toLogString(), self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(self.cost_data, data.card, true, fk.ReasonGive)
  end,
}
yanjun:addSkill(guanchao)
yanjun:addSkill(xunxian)
Fk:loadTranslationTable{
  ["yanjun"] = "严畯",
  ["guanchao"] = "观潮",
  [":guanchao"] = "出牌阶段开始时，你可以选择一项直到回合结束：1.当你使用牌时，若你此阶段使用过的所有牌的点数为严格递增，你摸一张牌；2.当你使用牌时，若你此阶段使用过的所有牌的点数为严格递减，你摸一张牌。",
  ["xunxian"] = "逊贤",
  [":xunxian"] = "每名其他角色的回合限一次，你使用或打出的牌置入弃牌堆时，你可以将之交给一名手牌比你多的角色。",
  ["@@guanchao_ascending-turn"] = "观潮：递增",
  ["@@guanchao_decending-turn"] = "观潮：递减",
  ["@guanchao_ascending-turn"] = "观潮：递增",
  ["@guanchao_decending-turn"] = "观潮：递减",
  ["#xunxian-choose"] = "逊贤：你可以将%arg交给一名手牌数大于你的角色",
}

Fk:loadTranslationTable{
  ["duji"] = "杜畿",
  ["andong"] = "安东",
  [":andong"] = "当你受到其他角色造成的伤害时，你可令伤害来源选择一项：1.防止此伤害，本回合弃牌阶段红桃牌不计入手牌上限；2.观看其手牌，若其中有红桃牌则你获得这些红桃牌。",
  ["yingshi"] = "应势",
  [":yingshi"] = "出牌阶段开始时，若没有武将牌旁有“酬”的角色，你可将所有红桃牌置于一名其他角色的武将牌旁，称为“酬”。若如此做，当一名角色使用【杀】对武将牌旁有“酬”的角色造成伤害后，其可以获得一张“酬”。当武将牌旁有“酬”的角色死亡时，你获得所有“酬”。",
}

local liuyan = General(extension, "liuyan", "qun", 3)
local tushe = fk.CreateTriggerSkill{
  name = "tushe",
  anim_type = "drawcard",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      data.card.type ~= Card.TypeEquip and
      data.firstTarget and
      #table.filter(player:getCardIds(Player.Hand), function(cid)
        return Fk:getCardById(cid).type == Card.TypeBasic end) == 0 and
      #AimGroup:getAllTargets(data.tos) > 0
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(#AimGroup:getAllTargets(data.tos), self.name)
  end,
}
local limu_targetmod = fk.CreateTargetModSkill{
  name = "#limu_targetmod",
  residue_func = function(self, player, skill)
    return #player:getCardIds(Player.Judge) > 0 and 999 or 0
  end,
  distance_limit_func = function(self, player, skill)
    return #player:getCardIds(Player.Judge) > 0 and 999 or 0
  end,
}
local limu = fk.CreateActiveSkill{
  name = "limu",
  anim_type = "control",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player) return not player:hasDelayedTrick("indulgence") end,
  target_filter = function() return false end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).suit == Card.Diamond
  end,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local cards = use.cards
    local card = Fk:cloneCard("indulgence")
    card:addSubcards(cards)
    room:useCard{
      from = use.from,
      tos = {{use.from}},
      card = card,
    }
    if player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        skillName = self.name
      }
    end
  end,
}
limu:addRelatedSkill(limu_targetmod)
liuyan:addSkill(tushe)
liuyan:addSkill(limu)
Fk:loadTranslationTable{
  ["liuyan"] = "刘焉",
  ["tushe"] = "图射",
  [":tushe"] = "当你使用非装备牌指定目标后，若你没有基本牌，则你可以摸X张牌（X为此牌指定的目标数）。",
  ["limu"] = "立牧",
  [":limu"] = "出牌阶段，你可以将一张方块牌当【乐不思蜀】对自己使用，然后回复1点体力；你的判定区有牌时，你使用牌没有次数和距离限制。",

  ["$tushe1"] = "据险以图进，备策而施为！",
  ["$tushe2"] = "夫战者，可时以奇险之策而图常谋！",
  ["$limu1"] = "今诸州纷乱，当立牧以定！",
  ["$limu2"] = "此非为偏安一隅，但求一方百姓安宁！",
  ["~liuyan"] = "季玉，望你能守好者益州疆土……",
}

local panjun = General(extension, "panjun", "wu", 3)
local guanwei = fk.CreateTriggerSkill{
  name = "guanwei",
  anim_type = "support",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and target.phase == Player.Play and target.tag[self.name] and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and not player:isNude() then
      local tag = target.tag[self.name]
      return #tag > 1 and table.every(tag, function (suit) return suit == tag[1] end) and not table.contains(tag, Card.NoSuit)
    end
  end,
  on_cost = function(self, event, target, player, data)
    return #player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#guanwei-invoke::"..target.id) > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(target, "guanwei-turn", 1)
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.EventPhaseChanging},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return player:hasSkill(self.name, true) and target.phase == Player.Play
    else
      return target == player and data.from == Player.Play
    end
  end,
  on_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      target.tag[self.name] = target.tag[self.name] or {}
      table.insert(target.tag[self.name], data.card.suit)
    else
      if player:getMark("guanwei-turn") > 0 then
        player.room:setPlayerMark(player, "guanwei-turn", 0)
        player:drawCards(2, self.name)
        player:gainAnExtraPhase(Player.Play)
      end
      player.tag[self.name] = {}
    end
  end,
}
local gongqing = fk.CreateTriggerSkill{
  name = "gongqing",
  frequency = Skill.Compulsory,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and data.from then
      return (data.from:getAttackRange() < 3 and data.damage > 1) or data.from:getAttackRange() > 3
    end
  end,
  on_use = function(self, event, target, player, data)
    if data.from:getAttackRange() < 3 then
      data.damage = 1
    elseif data.from:getAttackRange() > 3 then
      data.damage = data.damage + 1
    end
  end,
}
panjun:addSkill(guanwei)
panjun:addSkill(gongqing)
Fk:loadTranslationTable{
  ["panjun"] = "潘濬",
  ["guanwei"] = "观微",
  [":guanwei"] = "一名角色的出牌阶段结束时，若其于此回合内使用过的牌数大于1，且其于此回合内使用过的牌花色均相同，且你于此回合未发动过此技能，你可弃置一张牌。若如此做，其摸两张牌，然后其获得一个额外的出牌阶段。",
  ["gongqing"] = "公清",
  [":gongqing"] = "锁定技，当你受到伤害时，若伤害来源攻击范围小于3，则你只受到1点伤害；若伤害来源攻击范围大于3，则此伤害+1。",
  ["#guanwei-invoke"] = "观微：你可以弃置一张牌，令 %dest 摸两张牌并执行一个额外的出牌阶段",
}

Fk:loadTranslationTable{
  ["wangcan"] = "王粲",
  ["sanwen"] = "散文",
  [":sanwen"] = "每回合限一次，当你获得牌时，若你手中有与这些牌牌名相同的牌，你可以展示之，并弃置获得的同名牌，然后摸弃牌数两倍数量的牌。",
  ["qiai"] = "七哀",
  [":qiai"] = "限定技，当你进入濒死状态时，你可令其他每名角色交给你一张牌。",
  ["denglou"] = "登楼",
  [":denglou"] = "限定技，结束阶段开始时，若你没有手牌，你可以观看牌堆顶的四张牌，然后获得其中的非基本牌，并使用其中的基本牌（不能使用则弃置）。",
}
Fk:loadTranslationTable{
  ["sp__pangtong"] = "庞统",
  ["guolun"] = "过论",
  [":guolun"] = "出牌阶段限一次，你可展示一名其他角色的一张手牌。然后你可选择你的一张牌。若其选择的牌点数小，你与其交换这两张牌，其摸一张牌；若你选择的牌点数小，你与其交换这两张牌，你摸一张牌。",
  ["songsang"] = "送丧",
  [":songsang"] = "限定技，当其他角色死亡时，若你已受伤，你可回复1点体力；若你未受伤，你可加1点体力上限。若如此做，你获得〖展骥〗。",
  ["zhanji"] = "展骥",
  [":zhanji"] = "锁定技，当你于出牌阶段内因摸牌且并非因发动此技能而得到牌时，你摸一张牌。",
}
Fk:loadTranslationTable{
  ["sp__taishici"] = "太史慈",
  ["jixu"] = "击虚",
  [":jixu"] = "出牌阶段限一次，你可令体力值相同的至少一名其他角色各猜测你的手牌区里是否有【杀】。系统公布这些角色各自的选择和猜测结果。"..
  "若你的手牌区里：有【杀】，当你于此阶段内使用【杀】选择目标后，你令所有选择“否”的角色也成为此【杀】的目标；没有【杀】，你弃置所有选择“是”的角色的各一张牌。你摸X张牌（X为猜错的角色数）。若没有猜错的角色，你结束此阶段。",
}

local zhoufang = General(extension, "zhoufang", "wu", 3)
local duanfa = fk.CreateActiveSkill{
  name = "duanfa",
  anim_type = "drawcard",
  can_use = function(self, player)
    return player:getMark("duanfa-phase") < player.maxHp
  end,
  target_num = 0,
  min_card_num = 1,
  max_card_num = function()
    return Self.maxHp - Self:getMark("duanfa-phase")
  end,
  card_filter = function(self, to_select, selected)
    return #selected < (Self.maxHp - Self:getMark("duanfa-phase")) and Fk:getCardById(to_select).color == Card.Black
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player)
    room:drawCards(player, #effect.cards, self.name)
    room:addPlayerMark(player, "duanfa-phase", #effect.cards)
  end
}
local sp__youdi = fk.CreateTriggerSkill{
  name = "sp__youdi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#sp__youdi-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCardChosen(to, player, "he", self.name)
    room:throwCard({card}, self.name, player, to)
    if Fk:getCardById(card).trueName ~= "slash" and not to:isNude() then
      local card2 = room:askForCardChosen(player, to, "he", self.name)
      room:obtainCard(player, card2, false, fk.ReasonPrey)
    end
    if Fk:getCardById(card).color ~= Card.Black then
      player:drawCards(1, self.name)
    end
  end,
}
zhoufang:addSkill(duanfa)
zhoufang:addSkill(sp__youdi)
Fk:loadTranslationTable{
  ["zhoufang"] = "周鲂",
  ["duanfa"] = "断发",
  [":duanfa"] = "出牌阶段，你可以弃置任意张黑色牌，然后摸等量的牌（你每阶段以此法弃置的牌数总和不能大于体力上限）。",
  ["sp__youdi"] = "诱敌",
  [":sp__youdi"] = "结束阶段，你可以令一名其他角色弃置你一张手牌，若弃置的牌不是【杀】，则你获得其一张牌；若弃置的牌不是黑色，则你摸一张牌。",
  ["#sp__youdi-choose"] = "诱敌：令一名角色弃置你一张牌，若不为【杀】，你获得其一张牌；若不为黑色，你摸一张牌",
}

Fk:loadTranslationTable{
  ["lvdai"] = "吕岱",
  ["qinguo"] = "勤国",
  [":qinguo"] = "①当你于回合内使用装备牌结算结束后，你可视为使用一张【杀】。②当你的装备区里的牌移动后，或装备牌移至你的装备区后，若你装备区里的牌数与你的体力值相等且与此次移动之前你装备区里的牌数不等，你回复1点体力。",
}

local liuyao = General(extension, "liuyao", "qun", 4)
local kannan = fk.CreateActiveSkill{
  name = "kannan",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:getMark("kannan-phase") == 0 and player:usedSkillTimes(self.name, Player.HistoryPhase) < player.hp
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and to_select ~= Self.id and target:getMark("kannan-phase") == 0 and not target:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:addPlayerMark(target, "kannan-phase", 1)
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      room:addPlayerMark(player, "@kannan", 1)
      room:addPlayerMark(player, "kannan-phase", 1)
    elseif pindian.results[target.id].winner == target then
      room:addPlayerMark(target, "@kannan", 1)
    end
  end,
}
local kannan_record = fk.CreateTriggerSkill{
  name = "#kannan_record",

  refresh_events = {fk.PreCardUse},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@kannan") > 0 and data.card.trueName == "slash"
  end,
  on_refresh = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + player:getMark("@kannan")
    player.room:setPlayerMark(player, "@kannan", 0)
  end,
}
kannan:addRelatedSkill(kannan_record)
liuyao:addSkill(kannan)
Fk:loadTranslationTable{
  ["liuyao"] = "刘繇",
  ["kannan"] = "戡难",
  [":kannan"] = "出牌阶段，若你于此阶段内发动过此技能的次数小于X（X为你的体力值），你可与你于此阶段内未以此法拼点过的一名角色拼点。若：你赢，你使用的下一张【杀】的伤害值基数+1且你于此阶段内不能发动此技能；其赢，其使用的下一张【杀】的伤害值基数+1。",
  ["@kannan"] = "戡难",
}
Fk:loadTranslationTable{
  ["lvqian"] = "吕虔",
  ["weilu"] = "威虏",
  [":weilu"] = "锁定技，当你受到其他角色造成的伤害后，伤害来源在你的下回合出牌阶段开始时失去体力至1，回合结束时其回复以此法失去的体力值。",
  ["zengdao"] = "赠刀",
  [":zengdao"] = "限定技，出牌阶段，你可以将装备区内任意数量的牌置于一名其他角色的武将牌旁，该角色造成伤害时，移去一张“赠刀”牌，然后此伤害+1。",
}
Fk:loadTranslationTable{
  ["zhangliang"] = "张梁",
  ["jijun"] = "集军",
  [":jijun"] = "当武器牌或不为装备牌的牌于你的出牌阶段内指定第一个目标后，若此牌的使用者为你且你是此牌的目标之一，你可判定。当此次判定的判定牌移至弃牌堆后，你可将此判定牌置于武将牌上（称为“方”）。",
  ["fangtong"] = "方统",
  [":fangtong"] = "结束阶段开始时，若有“方”，你可弃置一张牌，若如此做，你将至少一张“方”置入弃牌堆。若此牌与你以此法置入弃牌堆的所有“方”的点数之和为36，你对一名其他角色造成3点雷电伤害。",
}
--司马徽
local xurong = General(extension, "xurong", "qun", 4)
local xionghuo = fk.CreateActiveSkill{
  name = "xionghuo",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:getMark("@baoli") > 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and Fk:currentRoom():getPlayerById(to_select):getMark("@baoli") == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:removePlayerMark(player, "@baoli", 1)
    room:addPlayerMark(target, "@baoli", 1)
  end,
}
local xionghuo_record = fk.CreateTriggerSkill{
  name = "#xionghuo_record",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.DamageCaused, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill("xionghuo", false, true) then
      if event == fk.GameStart then
        return true
      elseif event == fk.DamageCaused then
        return target == player and data.to ~= player and data.to:getMark("@baoli") > 0
      else
        return target ~= player and target:getMark("@baoli") > 0 and target.phase == Player.Play
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      room:addPlayerMark(player, "@baoli", 3)
    elseif event == fk.DamageCaused then
      data.damage = data.damage + 1
    else
      room:removePlayerMark(target, "@baoli", 1)
      room:addPlayerMark(target, "xionghuo-clear", 1)
      local n = 3
      if target:isNude() or player.dead then
        n = 2
      end
      local rand = math.random(1, n)
      if rand == 1 then
        room:damage {
          to = target,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = "xionghuo",
        }
      elseif rand == 2 then
        room:loseHp(target, 1, "xionghuo")
        room:addPlayerMark(target, "MinusMaxCards-turn", 1)
      else
        local dummy = Fk:cloneCard("dilu")
        if not target:isKongcheng() then
          dummy:addSubcard(table.random(target.player_cards[Player.Hand]))
        end
        if #target.player_cards[Player.Equip] > 0 then
          dummy:addSubcard(table.random(target.player_cards[Player.Equip]))
        end
        room:obtainCard(player.id, dummy, false, fk.ReasonPrey)
      end
    end
  end,
}
local xionghuo_prohibit = fk.CreateProhibitSkill{
  name = "#xionghuo_prohibit",
  is_prohibited = function(self, from, to, card)
    if to:hasSkill("xionghuo") and from:getMark("xionghuo-clear") > 0 then
      return card.trueName == "slash"
    end
  end,
}
local shajue = fk.CreateTriggerSkill{
  name = "shajue",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    if target ~= player and player:hasSkill(self.name) then
      return data.damage ~= nil and data.damage.card ~= nil and target.hp < 0 and
      player.room:getCardArea(data.damage.card) == Card.Processing
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@baoli", 1)
    room:obtainCard(player, data.damage.card, true, fk.ReasonPrey)
  end
}
xionghuo:addRelatedSkill(xionghuo_record)
xionghuo:addRelatedSkill(xionghuo_prohibit)
xurong:addSkill(xionghuo)
xurong:addSkill(shajue)
Fk:loadTranslationTable{
  ["xurong"] = "徐荣",
  ["xionghuo"] = "凶镬",
  [":xionghuo"] = "游戏开始时，你获得3个“暴戾”标记。出牌阶段，你可以交给一名其他角色一个“暴戾”标记，你对有此标记的角色造成的伤害+1，且其出牌阶段开始时，移去“暴戾”并随机执行一项：<br>"..
  "受到1点火焰伤害且本回合不能对你使用【杀】；<br>"..
  "流失1点体力且本回合手牌上限-1；<br>"..
  "你随机获得其一张手牌和一张装备区里的牌。",
  ["shajue"] = "杀绝",
  [":shajue"] = "锁定技，其他角色进入濒死状态时，若其需要超过一张【桃】或【酒】救回，则你获得一个“暴戾”标记，并获得使其进入濒死状态的牌。",
  ["#xionghuo_record"] = "凶镬",
  ["@baoli"] = "暴戾",

  ["$xionghuo1"] = "此镬加之于你，定有所伤！",
  ["$xionghuo2"] = "凶镬沿袭，怎会轻易无伤？",
  ["$shajue1"] = "杀伐决绝，不留后患。",
  ["$shajue2"] = "吾即出，必绝之！",
  ["~xurong"] = "此生无悔，心中无愧。",
}

local lijue = General(extension, "lijue", "qun", 4, 6)
local langxi = fk.CreateTriggerSkill{
  name = "langxi",
  anim_type = "offensive",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      not table.every(player.room:getOtherPlayers(player), function(p)
        return p.hp > player.hp
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p.hp <= player.hp end), function(p) return p.id end), 1, 1, "#langxi-choose", self.name)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:damage({
      from = player,
      to = room:getPlayerById(self.cost_data),
      damage = math.random(0, 2),
      skillName = self.name,
    })
  end,
}
local yisuan = fk.CreateTriggerSkill{
  name = "yisuan",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Play and
      player:usedSkillTimes(self.name) < 1 and
      data.card.type == Card.TypeTrick and
      data.card.sub_type ~= Card.SubtypeDelayedTrick and
      player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:obtainCard(player.id, data.card, true, fk.ReasonPrey)
  end,
}
lijue:addSkill(langxi)
lijue:addSkill(yisuan)
Fk:loadTranslationTable{
  ["lijue"] = "李傕",
  ["langxi"] = "狼袭",
  [":langxi"] = "准备阶段开始时，你可以对一名体力值不大于你的其他角色随机造成0~2点伤害。",
  ["#langxi-choose"] = "狼袭：请选择一名体力值不大于你的其他角色，对其随机造成0~2点伤害",
  ["yisuan"] = "亦算",
  [":yisuan"] = "每阶段限一次，当你于出牌阶段内使用普通锦囊牌结算结束后，你可以减1点体力上限，然后获得此牌。",

  ["$langxi1"] = "袭夺之势，如狼噬骨。",
  ["$langxi2"] = "引吾至此，怎能不袭掠之？",
  ["$yisuan1"] = "吾亦能善算谋划。",
  ["$yisuan2"] = "算计人心，我也可略施一二。",
  ["~lijue"] = "若无内讧，也不至如此。",
}

local guosi = General(extension, "guosi", "qun", 4)
local tanbei = fk.CreateActiveSkill{
  name = "tanbei",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local target = room:getPlayerById(use.tos[1])
    local choices = {"tanbei2"}
    if not target:isNude() then
      table.insert(choices, 1, "tanbei1")
    end
    local choice = room:askForChoice(target, choices, self.name)
    room:addPlayerMark(target, choice.."-turn", 1)
    if choice == "tanbei1" then
      local id = table.random(target:getCardIds{Player.Hand, Player.Equip, Player.Judge})
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end,
}
local tanbei_prohibit = fk.CreateProhibitSkill{
  name = "#tanbei_prohibit",
  is_prohibited = function(self, from, to, card)
    return from:hasSkill(self.name) and to:getMark("tanbei1-turn") > 0
  end,
}
local tanbei_record = fk.CreateTriggerSkill{
  name = "#tanbei_record",

  refresh_events = {fk.TargetSpecifying},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
        if player.room:getPlayerById(id):getMark("tanbei2-turn") > 0 then
          return true
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player:addCardUseHistory(data.card.trueName, -1)
  end,
}
local tanbei_distance = fk.CreateDistanceSkill{
  name = "#tanbei_distance",
  correct_func = function(self, from, to)
    if from:hasSkill(self.name) then
      if to:getMark("tanbei2-turn") > 0 then
        from:setFixedDistance(to, 1)
      else
        from:removeFixedDistance(to)
      end
    end
    return 0
  end,
}
local sidao = fk.CreateTriggerSkill{
  name = "sidao",
  anim_type = "offensive",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play and player:usedSkillTimes(self.name) == 0 and not player:isKongcheng() then
      return self.sidao_tos and #self.sidao_tos > 0
    end
  end,
  on_cost = function(self, event, target, player, data)  --TODO: target filter
    local tos, id = player.room:askForChooseCardAndPlayers(player, self.sidao_tos, 1, 1, ".|.|.|hand|.|.", "#sidao-cost", self.name, true)
    if #tos > 0 then
      self.cost_data = {tos[1], id}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useVirtualCard("snatch", {self.cost_data[2]}, player, player.room:getPlayerById(self.cost_data[1]), self.name)
  end,

  refresh_events = {fk.TargetSpecified},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and data.firstTarget
  end,
  on_refresh = function(self, event, target, player, data)
    self.sidao_tos = {}
    local mark = player:getMark("sidao-phase")
    if mark ~= 0 and #mark > 0 and #AimGroup:getAllTargets(data.tos) > 0 then
      for _, id in ipairs(AimGroup:getAllTargets(data.tos)) do
        if table.contains(mark, id) then
          table.insert(self.sidao_tos, id)
        end
      end
    end
    if #AimGroup:getAllTargets(data.tos) > 0 then
      mark = AimGroup:getAllTargets(data.tos)
      table.removeOne(mark, player.id)
    else
      mark = 0
    end
    player.room:setPlayerMark(player, "sidao-phase", mark)
  end,
}
tanbei:addRelatedSkill(tanbei_prohibit)
tanbei:addRelatedSkill(tanbei_record)
tanbei:addRelatedSkill(tanbei_distance)
guosi:addSkill(tanbei)
guosi:addSkill(sidao)
Fk:loadTranslationTable{
  ["guosi"] = "郭汜",
  ["tanbei"] = "贪狈",
  [":tanbei"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.令你随机获得其区域内的一张牌，此回合不能再对其使用牌；2. 令你此回合对其使用牌没有次数和距离限制。",
  ["sidao"] = "伺盗",
  [":sidao"] = "出牌阶段限一次，当你对一名其他角色连续使用两张牌后，你可将一张手牌当【顺手牵羊】对其使用（目标须合法）。",
  ["tanbei1"] = "其随机获得你区域内的一张牌，此回合不能再对你使用牌",
  ["tanbei2"] = "此回合对你使用牌无次数和距离限制",
  ["#sidao-cost"] = "伺盗：你可将一张手牌当【顺手牵羊】对相同的目标使用",

  ["$tanbei1"] = "此机，我怎么会错失。",
  ["$tanbei2"] = "你的东西，现在是我的了！",
  ["$sidao1"] = "连发伺动，顺手可得。	",
  ["$sidao2"] = "伺机而动，此地可窃。",
  ["~guosi"] = "伍习，你……",
}

local zhangji = General(extension, "zhangji", "qun", 4)
local lveming = fk.CreateActiveSkill{
  name = "lveming",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and #target.player_cards[Player.Equip] < #Self.player_cards[Player.Equip]
  end,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local target = room:getPlayerById(use.tos[1])
    local choices = {}
    for i = 1, 13, 1 do
      table.insert(choices, tostring(i))
    end
    local choice = room:askForChoice(target, choices, self.name)
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if tostring(judge.card.number) == choice then
      room:damage{
        from = player,
        to = target,
        damage = 2,
        skillName = self.name,
      }
    elseif not target:isAllNude() then
      local id = table.random(target:getCardIds{Player.Hand, Player.Equip, Player.Judge})
      room:obtainCard(player.id, id, false, fk.ReasonPrey)
    end
  end,
}
local tunjun = fk.CreateActiveSkill{
  name = "tunjun",
  anim_type = "drawcard",
  target_num = 1,
  card_num = 0,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player:usedSkillTimes("lveming", Player.HistoryGame) > 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and #Fk:currentRoom():getPlayerById(to_select).player_cards[Player.Equip] < 4  --TODO: no treasure yet
  end,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local target = room:getPlayerById(use.tos[1])
    local n = player:usedSkillTimes("lveming", Player.HistoryGame)
    for i = 1, n, 1 do
      local types = {Card.SubtypeWeapon, Card.SubtypeArmor, Card.SubtypeDefensiveRide, Card.SubtypeOffensiveRide, Card.SubtypeTreasure}
      local cards = {}
      for i = 1, #room.draw_pile, 1 do
        local card = Fk:getCardById(room.draw_pile[i])
        for _, type in ipairs(types) do
          if card.sub_type == type and target:getEquipment(type) == nil then
            table.insertIfNeed(cards, room.draw_pile[i])
          end
        end
      end
      if #cards > 0 then
        room:useCard({
          from = target.id,
          tos = {{target.id}},
          card = Fk:getCardById(table.random(cards)),
        })
      end
    end
  end,
}
zhangji:addSkill(lveming)
zhangji:addSkill(tunjun)
Fk:loadTranslationTable{
  ["zhangji"] = "张济",
  ["lveming"] = "掠命",
  [":lveming"] = "出牌阶段限一次，你选择一名装备区装备少于你的其他角色，令其选择一个点数，然后你进行判定：若点数相同，你对其造成2点伤害；不同，你随机获得其区域内的一张牌。",
  ["tunjun"] = "屯军",
  [":tunjun"] = "限定技，出牌阶段，你可以选择一名角色，令其随机使用牌堆中的X张不同类型的装备牌。（不替换原有装备，X为你发动“掠命”的次数）",

  ["$lveming1"] = "劫命掠财，毫不费力。",
  ["$lveming2"] = "人财，皆掠之，哈哈！",
  ["$tunjun1"] = "得封侯爵，屯军弘农。",
  ["$tunjun2"] = "屯军弘农，养精蓄锐。",
  ["~zhangji"] = "哪，哪里来的乱箭？",
}

local fanchou = General(extension, "fanchou", "qun", 4)
local xingluan = fk.CreateTriggerSkill{
  name = "xingluan",
  anim_type = "drawcard",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and
    data.tos and #data.tos == 1 and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = {getCardByPattern(room, ".|6")}
    if #card > 0 then
      room:moveCards({
        ids = card,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
fanchou:addSkill(xingluan)
Fk:loadTranslationTable{
  ["fanchou"] = "樊稠",
  ["xingluan"] = "兴乱",
  [":xingluan"] = "出牌阶段限一次，当你使用的仅指定一个目标的牌结算完成后，你可以从牌堆里获得一张点数为6的牌。",

  ["$xingluan1"] = "大兴兵争，长安当乱。",
  ["$xingluan2"] = "勇猛兴军，乱世当立。",
  ["~fanchou"] = "唉，稚然，疑心甚重。",
}
--张琪瑛 卫温诸葛直 吕凯 张恭 2019.4.28
local zhangqiying = General(extension, "zhangqiying", "qun", 3, 3, General.Female)
local falu = fk.CreateTriggerSkill{
  name = "falu",
  anim_type = "special",
  frequency = Skill.Compulsory,
  events = {fk.GameStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.GameStart then
        return true
      else
        for _, move in ipairs(data) do
          if move.from == player.id and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
            self.cost_data = {}
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                local suit = Fk:getCardById(info.cardId):getSuitString()
                if player:getMark("@@falu" .. suit) == 0 then
                  table.insertIfNeed(self.cost_data, suit)
                end
              end
            end
            return #self.cost_data > 0
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local suits = {"spade", "club", "heart", "diamond"}
      for i = 1, 4, 1 do
        room:addPlayerMark(player, "@@falu" .. suits[i], 1)
      end
    else
      for _, suit in ipairs(self.cost_data) do
        room:addPlayerMark(player, "@@falu" .. suit, 1)
      end
    end
  end,
}
local zhenyi = fk.CreateTriggerSkill {
  name = "zhenyi",
  anim_type = "control",
  events = {fk.AskForRetrial, fk.AskForPeaches, fk.DamageCaused, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) then
      if event == fk.AskForRetrial then
        return player:getMark("@@faluspade") > 0
      elseif event == fk.AskForPeaches then
        return target == player and player:getMark("@@faluclub") > 0 and player.dying and not player:isKongcheng()
      elseif event == fk.DamageCaused then
        return target == player and player:getMark("@@faluheart") > 0
      elseif event == fk.Damaged then
        return target == player and player:getMark("@@faludiamond") > 0 and data.damageType ~= fk.NormalDamage
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AskForPeaches then
      local card = room:askForCard(player, 1, 1, false, self.name, true, ".", "#zhenyi2")
      if #card > 0 then
        self.cost_data = card
        return true
      end
    else
      local prompt
      if event == fk.AskForRetrial then
        prompt = "#zhenyi1::"..target.id
      elseif event == fk.DamageCaused then
        prompt = "#zhenyi3::"..data.to.id
      elseif event == fk.Damaged then
        prompt = "#zhenyi4"
      end
      return room:askForSkillInvoke(player, self.name, nil, prompt)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AskForRetrial then
      room:removePlayerMark(player, "@@faluspade", 1)
      local choice = room:askForChoice(player, {"spade", "heart"}, self.name, self.name)
      if choice == "spade" then
        data.card.suit = Card.Spade
      else
        data.card.suit = Card.Heart
      end
      data.card.number = 5
    elseif event == fk.AskForPeaches then
      room:removePlayerMark(player, "@@faluclub", 1)
      local peach = Fk:cloneCard("peach")
      peach:addSubcards(self.cost_data)
      peach.skillName = self.name
      room:useCard({
        card = peach,
        from = player.id,
        tos = {{target.id}},
      })
    elseif event == fk.DamageCaused then
      room:removePlayerMark(player, "@@faluheart", 1)
      self.zhenyi_damage = false
      local judge = {
        who = data.to,
        reason = self.name,
        pattern = ".|.|spade,club",
      }
      room:judge(judge)
      if judge.card.color == Card.Black then
        data.damage = data.damage + 1
      end
    elseif event == fk.Damaged then
      room:removePlayerMark(player, "@@faludiamond", 1)
      local cards = {}
      table.insert(cards, getCardByPattern(room, ".|.|.|.|.|basic"))
      table.insert(cards, getCardByPattern(room, ".|.|.|.|.|trick"))
      table.insert(cards, getCardByPattern(room, ".|.|.|.|.|equip"))
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
      end
    end
  end,
}
local dianhua = fk.CreateTriggerSkill{
  name = "dianhua",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and (player.phase == Player.Start or player.phase == Player.Finish) then
      self.cost_data = 0
      for _, mark in ipairs(player:getMarkNames()) do
        if string.find(mark, "@@falu") then
          self.cost_data = self.cost_data + 1
        end
      end
      return self.cost_data > 0
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:askForGuanxing(player, room:getNCards(self.cost_data), nil, {0, 0})
  end,
}
zhangqiying:addSkill(falu)
zhangqiying:addSkill(zhenyi)
zhangqiying:addSkill(dianhua)
Fk:loadTranslationTable{
  ["zhangqiying"] = "张琪瑛",
  ["falu"] = "法箓",
  [":falu"] = "锁定技，当你的牌因弃置而移至弃牌堆后，根据这些牌的花色，你获得对应标记：<br>"..
  "♠，你获得1枚“紫微”；<br>"..
  "♣，你获得1枚“后土”；<br>"..
  "<font color='red'>♥</font>，你获得1枚“玉清”；<br>"..
  "<font color='red'>♦</font>，你获得1枚“勾陈”。<br>"..
  "每种标记限拥有一个。游戏开始时，你获得以上四种标记。",
  ["zhenyi"] = "真仪",
  [":zhenyi"] = "你可以在以下时机弃置相应的标记来发动以下效果：<br>"..
  "当一张判定牌生效前，你可以弃置“紫微”，然后将判定结果改为♠5或<font color='red'>♥5</font>；<br>"..
  "当你处于濒死状态时，你可以弃置“后土”，然后将你的一张手牌当【桃】使用；<br>"..
  "当你造成伤害时，你可以弃置“玉清”，然后你进行一次判定，若结果为黑色，此伤害+1；<br>"..
  "当你受到属性伤害后，你可以弃置“勾陈”，然后你从牌堆中随机获得三种类型的牌各一张。",
  ["dianhua"] = "点化",
  [":dianhua"] = "准备阶段或结束阶段，你可以观看牌堆顶的X张牌（X为你的标记数）。若如此做，你将这些牌以任意顺序放回牌堆顶。",
  ["@@faluspade"] = "♠紫微",
  ["@@faluclub"] = "♣后土",
  ["@@faluheart"] = "<font color='red'>♥</font>玉清",
  ["@@faludiamond"] = "<font color='red'>♦</font>勾陈",
  ["#zhenyi1"] = "真仪：你可以弃置♠紫微，将 %dest 的判定结果改为♠5或<font color='red'>♥5</font>",
  ["#zhenyi2"] = "真仪：你可以弃置♣后土，将一张手牌当【桃】使用",
  ["#zhenyi3"] = "真仪：你可以弃置<font color='red'>♥</font>玉清，你进行判定，若结果为黑色，你对 %dest 造成的伤害+1",
  ["#zhenyi4"] = "真仪：你可以弃置<font color='red'>♦</font>勾陈，从牌堆中随机获得三种类型的牌各一张",

  ["$falu1"] = "求法之道，以司箓籍。",
  ["$falu2"] = "取舍有法，方得其法。",
  ["$zhenyi1"] = "不疾不徐，自爱自重。",
  ["$zhenyi2"] = "紫薇星辰，斗数之仪。",
  ["$dianhua1"] = "大道无形，点化无为。",
  ["$dianhua2"] = "得此点化，必得大道。",
  ["~zhangqiying"] = "米碎面散，我心欲绝。",
}
--沙摩柯 忙牙长 许贡 张昌蒲 2019.8.20
local shamoke = General(extension, "shamoke", "shu", 4)
local jilis = fk.CreateTriggerSkill{
  name = "jilis",
  anim_type = "drawcard",
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player:getMark("@jilis-turn") == player:getAttackRange()
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(player:getAttackRange())
  end,

  refresh_events = {fk.CardUsing, fk.CardResponding},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@jilis-turn", 1)
  end,
}
shamoke:addSkill(jilis)
Fk:loadTranslationTable{
  ["shamoke"] = "沙摩柯",
  ["jilis"] = "蒺藜",
  [":jilis"] = "当你于一回合内使用或打出第X张牌时，你可以摸X张牌（X为你的攻击范围）。",
  ["@jilis-turn"] = "蒺藜",

  ["$jilis1"] = "蒺藜骨朵，威震慑敌！",
  ["$jilis2"] = "看我一招，铁蒺藜骨朵！",
  ["~shamoke"] = "五溪蛮夷，不可能输！",
}

local mangyachang = General(extension, "mangyachang", "qun", 4)
local jiedao = fk.CreateTriggerSkill{
  name = "jiedao",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if player:getMark("jiedao-turn") == 0 then
        player.room:addPlayerMark(player, "jiedao-turn", 1)
        return player:isWounded()
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#jiedao-invoke::"..data.to.id..":"..player:getLostHp())
  end,
  on_use = function(self, event, target, player, data)
    local n = player:getLostHp()
    data.damage = data.damage + n
    data.jiedao_extra = n
  end,

  refresh_events = {fk.Damage},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and not data.to.dead and data.jiedao_extra and data.jiedao_extra > 0 and not player:isNude()
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local n = data.jiedao_extra
    if #player:getCardIds{Player.Hand, Player.Equip} <= n then
      player:throwAllCards("he")
    else
      room:askForDiscard(player, n, n, true, self.name, false, ".", "#jiedao-discard:::"..n)
    end
  end,
}
mangyachang:addSkill(jiedao)
Fk:loadTranslationTable{
  ["mangyachang"] = "忙牙长",
  ["jiedao"] = "截刀",
  [":jiedao"] = "当你每回合第一次造成伤害时，你可令此伤害至多+X（X为你损失的体力值）。然后若受到此伤害的角色没有死亡，你弃置等同于此伤害加值的牌。",
  ["#jiedao-invoke"] = "截刀：你可以令你对 %dest 造成的伤害+%arg",
  ["#jiedao-discard"] = "截刀：你需弃置等同于此伤害加值的牌（%arg张）",

  ["$jiedao1"] = "截头大刀的威力，你来尝尝？",
  ["$jiedao2"] = "我这大刀，可是不看情面的。",
  ["~mangyachang"] = "黄骠马也跑不快了……",
}

local wenyang = General(extension, "wenyang", "wei", 5)
local lvli = fk.CreateTriggerSkill{
  name = "lvli",
  anim_type = "drawcard",
  events = {fk.Damage, fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and #player.player_cards[Player.Hand] ~= player.hp then
      if #player.player_cards[Player.Hand] > player.hp and not player:isWounded() then return end
      local n = 1
      if player:usedSkillTimes("choujue", Player.HistoryGame) > 0 then
        if player.phase ~= Player.NotActive then
          n = 2
        end
      end
      if event == fk.Damage then
        return player:usedSkillTimes(self.name) < n
      else
        return player:usedSkillTimes("beishui", Player.HistoryGame) > 0 and player:usedSkillTimes(self.name) < n
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local n = #player.player_cards[Player.Hand] - player.hp
    if n < 0 then
      player:drawCards(-n, self.name)
    else
      player.room:recover{
        who = player,
        num = math.min(n, player:getLostHp()),
        recoverBy = player,
        skillName = self.name
      }
    end
  end
}
local choujue = fk.CreateTriggerSkill{
  name = "choujue",
  anim_type = "special",
  frequency = Skill.Wake,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return math.abs(#player.player_cards[Player.Hand] - player.hp) > 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "beishui", nil)
  end,
}
local beishui = fk.CreateTriggerSkill{
  name = "beishui",
  anim_type = "special",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player.player_cards[Player.Hand] < 2 or player.hp < 2
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, self.name, 1)
    room:changeMaxHp(player, -1)
    room:handleAddLoseSkills(player, "qingjiao", nil)
  end,
}
local qingjiao = fk.CreateTriggerSkill{
  name = "qingjiao",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:throwAllCards("h")
    
    local wholeCards = table.clone(room.draw_pile)
    table.insertTable(wholeCards, room.discard_pile)

    local cardSubtypeStrings = {
      [Card.SubtypeWeapon] = "weapon",
      [Card.SubtypeArmor] = "armor",
      [Card.SubtypeDefensiveRide] = "defensive_horse",
      [Card.SubtypeOffensiveRide] = "offensive_horse",
      [Card.SubtypeTreasure] = "treasure",
    }

    local cardDic = {}
    for _, id in ipairs(wholeCards) do
      local card = Fk:getCardById(id)
      local cardName = card.type == Card.TypeEquip and cardSubtypeStrings[card.sub_type] or card.trueName
      cardDic[cardName] = cardDic[cardName] or {}
      table.insert(cardDic[cardName], id)
    end

    local toObtain = {}
    while #toObtain < 8 and next(cardDic) ~= nil do
      local dicLength = 0
      for _, ids in pairs(cardDic) do
        dicLength = dicLength + #ids
      end

      local randomIdx = math.random(1, dicLength)
      dicLength = 0
      for cardName, ids in pairs(cardDic) do
        dicLength = dicLength + #ids
        if dicLength >= randomIdx then
          table.insert(toObtain, ids[dicLength - randomIdx + 1])
          cardDic[cardName] = nil
          break
        end
      end
    end

    if #toObtain > 0 then
      room:moveCards({
        ids = toObtain,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,

  refresh_events = {fk.EventPhaseStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish and player:usedSkillTimes(self.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player:throwAllCards("he")
  end,
}
wenyang:addSkill(lvli)
wenyang:addSkill(choujue)
wenyang:addRelatedSkill(beishui)
wenyang:addRelatedSkill(qingjiao)
Fk:loadTranslationTable{
  ["wenyang"] = "文鸯",
  ["lvli"] = "膂力",
  [":lvli"] = "每名角色的回合限一次，当你造成伤害后，你可以将手牌摸至与体力值相同或将体力回复至与手牌数相同。",
  ["choujue"] = "仇决",
  [":choujue"] = "觉醒技，每名角色的回合结束时，若你的手牌数和体力值相差3或更多，你减1点体力上限并获得〖背水〗，然后修改〖膂力〗为“每名其他角色的回合限一次（在自己的回合限两次）”。",
  ["beishui"] = "背水",
  [":beishui"] = "觉醒技，准备阶段，若你的手牌数或体力值小于2，你减1点体力上限并获得〖清剿〗，然后修改〖膂力〗为“当你造成或受到伤害后”。",
  ["qingjiao"] = "清剿",
  [":qingjiao"] = "出牌阶段开始时，你可以弃置所有手牌，然后从牌堆或弃牌堆中随机获得八张牌名各不相同且副类别不同的牌。若如此做，结束阶段，你弃置所有牌。",

  ["$lvli1"] = "此击若中，万念俱灰！",
  ["$lvli2"] = "姿器膂力，万人之雄。",
  ["$choujue1"] = "家仇未报，怎可独安？",
  ["$choujue2"] = "逆臣之军，不足畏惧！",
  ["$beishui1"] = "某若退却半步，诸将可立斩之！",
  ["$beishui2"] = "效淮阴之举，力敌数千！",
  ["$qingjiao1"] = "慈不掌兵，义不养财！",
  ["$qingjiao2"] = "清蛮夷之乱，剿不臣之贼！",
  ["~wenyang"] = "痛贯心膂，天灭大魏啊！",
}

local jianggan = General(extension, "jianggan", "wei", 3)
local weicheng = fk.CreateTriggerSkill{
  name = "weicheng",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self.name) and #player.player_cards[Player.Hand] < player.hp then
      for _, move in ipairs(data) do
        if move.from and move.from == player.id and move.to and move.to ~= player.id and move.toArea == Card.PlayerHand then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
  end,
}
local daoshu = fk.CreateActiveSkill{
  name = "daoshu",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function()
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local suits = {"spade", "heart", "club", "diamond"}
    local choice = room:askForChoice(player, suits, self.name)
    local card = room:askForCardChosen(player, target, 'h', self.name)
    room:obtainCard(player.id, card, true)
    if Fk:getCardById(card):getSuitString() == choice then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
      player:addSkillUseHistory(self.name, -1)
    else
      table.removeOne(suits, Fk:getCardById(card):getSuitString())
      local ids = room:askForCard(player, 1, 1, false, self.name, false, ".|.|"..table.concat(suits, ","), "#daoshu-give::"..target.id..":"..Fk:getCardById(card):getSuitString())
      if #ids > 0 then
        room:obtainCard(target, Fk:getCardById(ids[1]), true, fk.ReasonGive)
      else
        player:showCards(player.player_cards[Player.Hand])
      end
    end
  end,
}
jianggan:addSkill(weicheng)
jianggan:addSkill(daoshu)
Fk:loadTranslationTable{
  ["jianggan"] = "蒋干",
  ["weicheng"] = "伪诚",
  [":weicheng"] = "你交给其他角色手牌，或你的手牌被其他角色获得后，若你的手牌数小于体力值，你可以摸一张牌。",
  ["daoshu"] = "盗书",
  [":daoshu"] = "出牌阶段限一次，你可以选择一名其他角色并选择一种花色，然后获得该角色一张手牌。若此牌与你选择的花色：相同，你对其造成1点伤害且此技能视为未发动过；不同，你交给该角色一张其他花色的手牌（若没有需展示所有手牌）。",
  ["#daoshu-give"] = "盗书：你需交给 %dest 一张非%arg手牌，若没有则展示所有手牌",

  ["$weicheng1"] = "略施谋略，敌军便信以为真。",
  ["$weicheng2"] = "吾只观雅规，而非说客。",
  ["$daoshu1"] = "得此文书，丞相定可高枕无忧。",
  ["$daoshu2"] = "让我看看，这是什么机密。",
  ["~jianggan"] = "丞相，再给我一次机会啊！",
}

local guanlu = General(extension, "guanlu", "wei", 3)
local tuiyan = fk.CreateTriggerSkill{
  name = "tuiyan",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #room.draw_pile < 3 then
      room:shuffleDrawPile()
      if #room.draw_pile < 3 then
        room:gameOver("")
      end
    end
    local ids = {}
    for i = 1, 3, 1 do
      table.insert(ids, room.draw_pile[i])
    end
    room:fillAG(player, ids)
    room:delay(5000)
    room:closeAG(player)
  end,
}
local busuan = fk.CreateActiveSkill {
  name = "busuan",
  anim_type = "control",
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected)
    return #selected == 0 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card.type == Card.TypeBasic or card.type == Card.TypeTrick then
        table.insertIfNeed(names, card.trueName)
      end
    end
    local tag = {}
    for i = 1, 2, 1 do
      local name = room:askForChoice(player, names, self.name)
      table.insert(tag, name)
      table.removeOne(names, name)
    end
    target.tag[self.name] = tag
  end,
}
local busuan_record = fk.CreateTriggerSkill {
  name = "#busuan_record",

  refresh_events = {fk.DrawNCards},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name, true, true) then
      return type(target.tag["busuan"]) == "table" and #target.tag["busuan"] > 0 and data.n > 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    for _, name in ipairs(target.tag["busuan"]) do
      local id = getCardByPattern(room, name)
      if id == nil then
        id = getCardByPattern(room, name, room.discard_pile)
      end
      table.insert(cards, id)
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = target.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
    target.tag["busuan"] = {}
    data.n = 0
  end,
}
local mingjie = fk.CreateTriggerSkill {
  name = "mingjie",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(player:drawCards(1)[1])
    if card.color == Card.Black then
      if player.hp > 1 then
        room:loseHp(player, 1, self.name)
      end
      return
    else
      for i = 1, 2, 1 do
        if room:askForSkillInvoke(player, self.name) then
          card = Fk:getCardById(player:drawCards(1)[1])
          if card.color == Card.Black then
            if player.hp > 1 then
              room:loseHp(player, 1, self.name)
            end
            return
          end
        else
          return
        end
      end
    end
  end,
}
busuan:addRelatedSkill(busuan_record)
guanlu:addSkill(tuiyan)
guanlu:addSkill(busuan)
guanlu:addSkill(mingjie)
Fk:loadTranslationTable{
  ["guanlu"] = "管辂",
  ["tuiyan"] = "推演",
  [":tuiyan"] = "出牌阶段开始时，你可以观看牌堆顶的三张牌。",
  ["busuan"] = "卜算",
  [":busuan"] = "出牌阶段限一次，你可以选择一名其他角色，然后选择至多两张不同的卡牌名称（限基本牌或锦囊牌）。该角色下次摸牌阶段摸牌时，改为从牌堆或弃牌堆中获得你选择的牌。",
  ["mingjie"] = "命戒",
  [":mingjie"] = "结束阶段，你可以摸一张牌，若此牌为红色，你可以重复此流程直到摸到黑色牌或摸到第三张牌。当你以此法摸到黑色牌时，若你的体力值大于1，你失去1点体力。",

  ["$tuiyan1"] = "鸟语略知，万物略懂。",
  ["$tuiyan2"] = "玄妙之舒巧，推微而知晓。",
  ["$busuan1"] = "今日一卦，便知命数。",
  ["$busuan2"] = "喜仰视星辰，夜不肯寐。",
  ["$mingjie1"] = "戒律循规，不可妄贪。",
  ["$mingjie2"] = "王道文明，何忧不平。",
  ["~guanlu"] = "怀我好英，心非草木……",
}
--葛玄 蒲元 2019.10.22
Fk:loadTranslationTable{
  ["gexuan"] = "葛玄",
  ["lianhua"] = "炼化",
  [":lianhua"] = "你的回合外，每当有其他角色受到伤害后，你获得一个 “丹血”标记，直到你的出牌阶段开始。<br>"..
  "准备阶段，根据你获得的“丹血”标记的数量和颜色，你获得相应的游戏牌以及获得相应技能直到回合结束。<br>"..
  "3枚或以下：“英姿”和【桃】；<br>"..
  "超过3枚且红色“丹血”较多：“观星”和【无中生有】；<br>"..
  "超过3枚且黑色“丹血”较多：“直言”和【顺手牵羊】；<br>"..
  "超过3枚且红色和黑色一样多：【杀】、【决斗】和“攻心”。",
  ["zhafu"] = "札符",
  [":zhafu"] = "限定技，出牌阶段，你可以选择一名其他角色。该角色的下个弃牌阶段开始时，其选择保留一张手牌，将其余手牌交给你。",
}

local puyuan = General(extension, "ty__puyuan", "shu", 4)
local puyuan_equips = {"&red_spear", "&quenched_blade", "&poisonous_dagger", "&water_sword", "&thunder_blade"}
local tianjiang = fk.CreateActiveSkill{
  name = "tianjiang",
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return #player.player_cards[Player.Equip] > 0
  end,
  card_filter = function(self, to_select, selected, targets)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Card.PlayerEquip
  end,
  target_filter = function(self, to_select, selected, cards)
    return #selected == 0 and #cards == 1 and to_select ~= Self.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card = Fk:getCardById(effect.cards[1])
    local type = card.sub_type
    if target:getEquipment(type) ~= nil then
      room:moveCards({
        ids = {target:getEquipment(type)},
        from = target.id,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
      })
    end
    room:moveCards({
      from = effect.from,
      ids = effect.cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      proposer = effect.from,
      skillName = self.name,
    })
    room:moveCards({
      ids = effect.cards,
      fromArea = Card.Processing,
      to = target.id,
      toArea = Card.PlayerEquip,
      moveReason = fk.ReasonPut,
      proposer = effect.from,
      skillName = self.name,
    })
    if table.contains(puyuan_equips, card.name) then
      player:drawCards(2, self.name)
    end
  end,
}
local tianjiang_trigger = fk.CreateTriggerSkill{
  name = "#tianjiang_trigger",
  events = {fk.GameStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    repeat
      local id = table.random(room.draw_pile)
      if Fk:getCardById(id).type == Card.TypeEquip then
        if #cards == 0 then
          table.insertIfNeed(cards, id)
        elseif Fk:getCardById(id).sub_type ~= Fk:getCardById(cards[1]).sub_type then
          table.insertIfNeed(cards, id)
        end
      end
    until #cards == 2
    room:moveCards({
      fromArea = Card.DrawPile,
      ids = table.random(cards, 2),
      to = player.id,
      toArea = Card.PlayerEquip,
      moveReason = fk.ReasonJustMove,
      proposer = player.id,
      skillName = self.name,
    })
  end,
}
local zhuren = fk.CreateActiveSkill{
  name = "zhuren",
  anim_type = "special",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    local card = Fk:getCardById(effect.cards[1])
    local name = "slash"
    if card.name == "lightning" then
      name = "&thunder_blade"
    elseif card.suit == Card.Heart then
      name = "&red_spear"
    elseif card.suit == Card.Diamond then
      name = "&quenched_blade"
    elseif card.suit == Card.Spade then
      name = "&poisonous_dagger"
    elseif card.suit == Card.Club then
      name = "&water_sword"
    end
    if name ~= "slash" then
      for _, id in ipairs(Fk:getAllCardIds()) do
        if Fk:getCardById(id).name == name and Fk:currentRoom():getCardArea(id) ~= Card.Void then
          name = "slash"
          break
        end
      end
    end
    if name ~= "slash" and name ~= "lightning" then
      if (0 < card.number and card.number < 5 and math.random() > 0.85) or
        (4 < card.number and card.number < 9 and math.random() > 0.9) or
        (8 < card.number and card.number < 13 and math.random() > 0.95) then
        name = "slash"
        room:setCardEmotion(effect.cards[1], "judgebad")
      else
        room:setCardEmotion(effect.cards[1], "judgegood")
      end
    end
    room:delay(1000)
    if name == "slash" then
      local ids = {getCardByPattern(room, "slash")}
      if #ids > 0 then
        room:moveCards({
          ids = ids,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
      end
    else
      for _, id in ipairs(Fk:getAllCardIds()) do
        if Fk:getCardById(id).name == name then
          room:moveCards({
            ids = {id},
            fromArea = Card.Void,
            to = player.id,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonJustMove,
            proposer = player.id,
            skillName = self.name,
          })
          break
        end
      end
    end
  end,
}
local zhuren_destruct = fk.CreateTriggerSkill{
  name = "#zhuren_destruct",
  priority = 1.1,

  refresh_events = {fk.AfterCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self.name, true, true) then
      for _, move in ipairs(data) do
        return move.toArea == Card.DiscardPile
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      local ids = {}
      if move.toArea == Card.DiscardPile then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(puyuan_equips, Fk:getCardById(info.cardId).name) then
            table.insert(ids, info.cardId)
          end
        end
      end
      if #ids > 0 then
        for _, id in ipairs(ids) do
          table.insert(player.room.void, id)
          player.room:setCardArea(id, Card.Void, nil)
        end
      end
    end
  end,
}
tianjiang:addRelatedSkill(tianjiang_trigger)
zhuren:addRelatedSkill(zhuren_destruct)
puyuan:addSkill(tianjiang)
puyuan:addSkill(zhuren)
Fk:loadTranslationTable{
  ["ty__puyuan"] = "蒲元",
  ["tianjiang"] = "天匠",
  [":tianjiang"] = "游戏开始时，你随机获得两张不同副类别的装备牌，并置入你的装备区。出牌阶段，你可以将装备区里的一张牌移动至其他角色的装备区（可替换原装备），若你移动的是〖铸刃〗打造的装备，你摸两张牌。",
  ["zhuren"] = "铸刃",
  [":zhuren"] = "出牌阶段限一次，你可以弃置一张手牌。根据此牌的花色点数，你有一定概率打造成功并获得一张武器牌（若打造失败或武器已有则改为摸一张【杀】，花色决定武器名称，点数决定成功率）。此武器牌进入弃牌堆时，将其移出游戏。",
  ["#tianjiang_trigger"] = "天匠",
}
--辛毗 李肃 张温 2019.12.4
local zhangwen = General(extension, "ty__zhangwen", "wu", 3)
local ty__songshu = fk.CreateActiveSkill{
  name = "ty__songshu",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      player:setSkillUseHistory(self.name, 0, Player.HistoryPhase)
    else
      player:drawCards(2, self.name)
      target:drawCards(2, self.name)
    end
  end,
}
local sibian = fk.CreateTriggerSkill{
  name = "sibian",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Draw
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(4)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = self.name,
    })
    local min, max = 13, 1
    for _, id in ipairs(cards) do
      if Fk:getCardById(id).number < min then
        min = Fk:getCardById(id).number
      end
      if Fk:getCardById(id).number > max then
        max = Fk:getCardById(id).number
      end
    end
    local get = {}
    for i = #cards, 1, -1 do
      if Fk:getCardById(cards[i]).number == min or Fk:getCardById(cards[i]).number == max then
        table.insert(get, cards[i])
        table.removeOne(cards, cards[i])
      end
    end
    room:delay(1000)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(get)
    room:obtainCard(player, dummy, false, fk.ReasonJustMove)
    if #cards > 0 then
      local n = #player.player_cards[Player.Hand]
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if #p.player_cards[Player.Hand] < n then
          n = #p.player_cards[Player.Hand]
        end
      end
      local targets = {}
      for _, p in ipairs(room:getAlivePlayers()) do
        if #p.player_cards[Player.Hand] == n then
          table.insert(targets, p.id)
        end
      end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#sibian-choose", self.name)
      if #to > 0 then
        local dummy2 = Fk:cloneCard("dilu")
        dummy2:addSubcards(cards)
        room:obtainCard(room:getPlayerById(to[1]), dummy2, false, fk.ReasonGive)
      else
        room:moveCards({
          ids = cards,
          fromArea = Card.Processing,
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonJustMove,
          skillName = self.name,
        })
      end
    end
    return true
  end,
}
zhangwen:addSkill(ty__songshu)
zhangwen:addSkill(sibian)
Fk:loadTranslationTable{
  ["ty__zhangwen"] = "张温",
  ["ty__songshu"] = "颂蜀",
  [":ty__songshu"] = "出牌阶段限一次，你可以与一名其他角色拼点：若你没赢，你和该角色各摸两张牌；若你赢，视为本阶段此技能未发动过。",
  ["sibian"] = "思辩",
  [":sibian"] = "摸牌阶段，你可以放弃摸牌，改为亮出牌堆顶的4张牌，你获得其中所有点数最大和最小的牌，然后你可以将剩余的牌交给一名手牌数最少的角色。",
  ["#sibian-choose"] = "思辩：你可以将剩余的牌交给一名手牌数最少的角色",
}
--花鬘 2020.1.31

local huangfusong = General(extension, "ty__huangfusong", "qun", 4)
local ty__fenyue = fk.CreateActiveSkill{
  name = "ty__fenyue",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:usedSkillTimes(self.name, Player.HistoryPhase) < player:getMark(self.name)
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      if Fk:getCardById(pindian.fromCard.id).number < 6 then
        if not target:isNude() then
          local id = room:askForCardChosen(player, target, "he", self.name)
          room:obtainCard(player, id, false, fk.ReasonPrey)
        end
      end
      if Fk:getCardById(pindian.fromCard.id).number < 10 then
        local card = {getCardByPattern(room, "slash")}
        if #card > 0 then
          room:moveCards({
            ids = card,
            to = player.id,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonJustMove,
            proposer = player.id,
            skillName = self.name,
          })
        end
      end
      if Fk:getCardById(pindian.fromCard.id).number < 14 then
        room:useVirtualCard("thunder__slash", nil, player, target, self.name, true)
      end
    end
  end,
}
local ty__fenyue_record = fk.CreateTriggerSkill{
  name = "#ty__fenyue_record",

  refresh_events = {fk.GameStart, fk.BeforeGameOverJudge},
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.GameStart then
      local n = 0
      if room.settings.gameMode == "aaa_role_mode" then
        local total = #room.alive_players
        if player.role == "lord" or player.role == "loyalist" then
          if total == 8 then n = 4
          elseif total == 7 or total == 6 then n = 3
          elseif total == 5 then n = 2
          else n = 1
          end
        elseif player.role == "rebel" then
          if total == 8 or total == 7 then n = 4
          elseif total == 6 or total == 5 or total == 4 then n = 3
          elseif total == 3 then n = 2
          else n = 1
          end
        elseif player.role == "renegade" then
          n = total - 1
        end
      elseif room.settings.gameMode == "m_1v2_mode" or room.settings.gameMode == "m_2v2_mode" then
        n = 2
      end
      room:setPlayerMark(player, "ty__fenyue", n)
    else
      if player.role == "renegade" or target.role == "renegade" or
        (player.role == "lord" or player.role == "loyalist" and target.role == "rebel") or
        (player.role == "rebel" and target.role == "loyalist") then
        room:removePlayerMark(player, "ty__fenyue", 1)
      end
    end
  end,
}
ty__fenyue:addRelatedSkill(ty__fenyue_record)
huangfusong:addSkill(ty__fenyue)
Fk:loadTranslationTable{
  ["ty__huangfusong"] = "皇甫嵩",
  ["ty__fenyue"] = "奋钺",
  [":ty__fenyue"] = "出牌阶段限X次（X为与你不同阵营的存活角色数），你可以与一名角色拼点，若你赢，根据你拼点的牌的点数执行以下效果：小于等于K：视为对其使用一张雷【杀】；小于等于9：获得牌堆中的一张【杀】；小于等于5：获得其一张牌。",
}

local wangshuang = General(extension, "wangshuang", "wei", 8)
local zhuilie = fk.CreateTriggerSkill{
  name = "zhuilie",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash" and not player:inMyAttackRange(player.room:getPlayerById(data.to))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:addCardUseHistory(data.card.trueName, -1)
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".|.|.|.|.|equip",
    }
    room:judge(judge)
    if judge.card.sub_type and (judge.card.sub_type == Card.SubtypeWeapon or judge.card.sub_type == Card.SubtypeOffensiveRide or judge.card.sub_type == Card.SubtypeDefensiveRide) then
      data.additionalDamage = (data.additionalDamage or 0) + room:getPlayerById(data.to).hp - 1
    else
      room:loseHp(player, 1, self.name)
    end
  end,
}
local zhuilie_targetmod = fk.CreateTargetModSkill{
  name = "#zhuilie_targetmod",
  distance_limit_func =  function(self, player, skill)
    if player:hasSkill(self.name) and skill.trueName == "slash_skill" then
      return 999
    end
  end,
}
zhuilie:addRelatedSkill(zhuilie_targetmod)
wangshuang:addSkill(zhuilie)
Fk:loadTranslationTable{
  ["wangshuang"] = "王双",
  ["zhuilie"] = "追猎",
  [":zhuilie"] = "锁定技，你使用【杀】无距离限制；当你使用【杀】指定你攻击范围外的一名角色为目标后，此【杀】不计入次数且你进行一次判定，若结果为武器牌或坐骑牌，此【杀】伤害基数值增加至该角色的体力值，否则你失去1点体力。",
}

local xingdaorong = General(extension, "xingdaorong", "qun", 4, 6)
local xuhe = fk.CreateTriggerSkill{
  name = "xuhe",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) and player.phase == Player.Play then
      if event == fk.EventPhaseStart then
        return true
      else
        return not table.every(player.room:getOtherPlayers(player), function(p) return p.maxHp <= player.maxHp end)
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, self.name, nil, "#xuhe-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      room:changeMaxHp(player, -1)
      if not player.dead then
        local choice = room:askForChoice(player, {"xuhe_discard", "xuhe_draw"}, self.name)
        if choice == "xuhe_discard" then
          for _, p in ipairs(room:getAlivePlayers()) do
            if player:distanceTo(p) < 2 and not p:isNude() then
              room:doIndicate(player.id, {p.id})
              local id = room:askForCardChosen(player, p, "he", self.name)
              room:throwCard({id}, self.name, p, player)
            end
          end
        else
          for _, p in ipairs(room:getAlivePlayers()) do
            if player:distanceTo(p) < 2  then
              p:drawCards(1, self.name)
            end
          end
        end
      end
    else
      room:changeMaxHp(player, 1)
      local choices = {"draw2"}
      if player:isWounded() then
        table.insert(choices, "recover")
      end
      local choice = room:askForChoice(player, choices, self.name)
      if choice == "draw2" then
        player:drawCards(2)
      else
        room:recover({
          who = player,
          num = 1,
          recoverBy = player,
          skillName = self.name
        })
      end
    end
  end,
}
xingdaorong:addSkill(xuhe)
Fk:loadTranslationTable{
  ["xingdaorong"] = "邢道荣",
  ["xuhe"] = "虚猲",
  [":xuhe"] = "出牌阶段开始时，你可以减1点体力上限，然后你弃置距离1以内的每名角色各一张牌或令这些角色各摸一张牌。出牌阶段结束时，若你体力上限不为全场最高，你加1点体力上限，然后回复1点体力或摸两张牌。",
  ["#xuhe-invoke"] = "虚猲：你可以减1点体力上限，然后弃置距离1以内每名角色各一张牌或令这些角色各摸一张牌",
  ["xuhe_discard"] = "弃置距离1以内角色各一张牌",
  ["xuhe_draw"] = "距离1以内角色各摸一张牌",
}

local leitong = General(extension, "leitong", "shu", 4)
local kuiji = fk.CreateActiveSkill{
  name = "kuiji",
  anim_type = "offensive",
  target_num = 0,
  card_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name) == 0 and not player:hasDelayedTrick("supply_shortage")
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeBasic and Fk:getCardById(to_select).color == Card.Black
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local card = Fk:cloneCard("supply_shortage")
    card:addSubcards(effect.cards)
    room:useCard{
      from = effect.from,
      tos = {{effect.from}},
      card = card,
    }
    player:drawCards(1, self.name)
    local targets = {}
    local n = 0
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.hp > n then
        n = p.hp
      end
    end
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.hp == n then
        table.insert(targets, p.id)
      end
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#kuiji-damage", self.name, true)
    if #to > 0 then
      room:damage{
        from = player,
        to = room:getPlayerById(to[1]),
        damage = 2,
        skillName = self.name,
      }
    end
  end,
}
local kuiji_record = fk.CreateTriggerSkill{
  name = "#kuiji_record",
  anim_type = "support",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.damage and data.damage.skillName == "kuiji"
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    local n = 999
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if p.hp < n then
        n = p.hp
      end
    end
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if p.hp == n and p:isWounded() then
        table.insert(targets, p.id)
      end
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#kuiji-recover::"..target.id, self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
      player.room:recover({
        who = player.room:getPlayerById(self.cost_data),
        num = 1,
        recoverBy = player,
        skillName = "kuiji"
      })
  end,
}
kuiji:addRelatedSkill(kuiji_record)
leitong:addSkill(kuiji)
Fk:loadTranslationTable{
  ["leitong"] = "雷铜",
  ["kuiji"] = "溃击",
  [":kuiji"] = "出牌阶段限一次，你可以将一张黑色基本牌当作【兵粮寸断】对你使用，然后摸一张牌。若如此做，你可以对体力值最多的一名其他角色造成2点伤害。该角色因此进入濒死状态时，你可令另一名体力值最少的角色回复1点体力。",
  ["#kuiji-damage"] = "溃击：你可以对其他角色中体力值最大的一名角色造成2点伤害",
  ["#kuiji-recover"] = "溃击：你可以令除 %dest 以外体力值最小的一名角色回复1点体力",
  ["#kuiji_record"] = "溃击",

  ["$kuiji1"] = "绝域奋击，孤注一掷。",
  ["$kuiji2"] = "舍得一身剐，不畏君王威。",
  ["~leitong"] = "翼德救我……",
}

local wulan = General(extension, "wulan", "shu", 4)
local cuoruiw = fk.CreateTriggerSkill{
  name = "cuoruiw",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      if player:distanceTo(p) < 2 and not p:isAllNude() then
        table.insert(targets, p.id)
      end
    end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#cuoruiw-cost", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local id = room:askForCardChosen(player, room:getPlayerById(self.cost_data), "hej", self.name)
    local color = Fk:getCardById(id).color
    room:throwCard({id}, self.name, room:getPlayerById(self.cost_data), player)
    local targets = {}
    local targets1 = {}
    local targets2 = {}
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if not p:isKongcheng() then
        table.insertIfNeed(targets, p.id)
        table.insert(targets2, p.id)
      end
      if #p.player_cards[Player.Equip] > 0 then
        for _, id in ipairs(p.player_cards[Player.Equip]) do
          if Fk:getCardById(id).color == color then
            table.insertIfNeed(targets, p.id)
            table.insert(targets1, p.id)
            break
          end
        end
      end
    end
    table.removeOne(targets, self.cost_data)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#cuoruiw-use", self.name, true)
    local to
    if #tos > 0 then
      to = room:getPlayerById(tos[1])
    else
      to = room:getPlayerById(table.random(targets))
    end
    local choices = {}
    if table.contains(targets1, to.id) then
      table.insert(choices, "cuoruiw_equip")
    end
    if table.contains(targets2, to.id) then
      table.insert(choices, "cuoruiw_hand")
    end
    local choice = room:askForChoice(player, choices, self.name)
    if choice == "cuoruiw_equip" then
      local ids = {}
      for _, id in ipairs(to.player_cards[Player.Equip]) do
        if Fk:getCardById(id).color == color then
          table.insert(ids, id)
        end
      end
      if #ids == 1 then
        room:throwCard(ids, self.name, to, player)
      else
        local throw = {}
        room:fillAG(player, ids)
        while #ids > 0 and #throw < 2 do
          local id = room:askForAG(player, ids, true, self.name)
          if id ~= nil then
            room:takeAG(player, id, {player})
            table.insert(throw, id)
            table.removeOne(ids, id)
          else
            break
          end
        end
        room:closeAG(player)
        room:throwCard(throw, self.name, to, player)
      end
    else
      local cards = room:askForCardsChosen(player, to, 1, 2, "h", self.name)
      to:showCards(cards)
      room:delay(1500)
      local dummy = Fk:cloneCard("dilu")
      for _, id in ipairs(cards) do
        if Fk:getCardById(id).color == color then
          dummy:addSubcard(id)
        end
      end
      if #dummy.subcards > 0 then
        room:moveCards({
          from = to.id,
          ids = dummy.subcards,
          to = player.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonPrey,
          proposer = player.id,
          skillName = self.name,
        })
      end
    end
  end,
}
wulan:addSkill(cuoruiw)
Fk:loadTranslationTable{
  ["wulan"] = "吴兰",
  ["cuoruiw"] = "挫锐",
  [":cuoruiw"] = "出牌阶段开始时，你可以弃置一名你计算与其距离不大于1的角色区域里的一张牌。若如此做，你选择一项：1.弃置另一名其他角色装备区里至多两张与此牌颜色相同的牌；2.展示另一名其他角色的至多两张手牌，然后获得其中与此牌颜色相同的牌。",
  ["#cuoruiw-cost"] = "挫锐：你可以弃置距离不大于1的角色区域里的一张牌",
  ["#cuoruiw-use"] = "挫锐：选择另一名其他角色，弃置其至多两张颜色相同的装备，或展示其至多两张手牌",
  ["cuoruiw_equip"] = "弃置其至多两张颜色相同的装备",
  ["cuoruiw_hand"] = "展示其至多两张手牌并获得其中相同颜色牌",

  ["$cuoruiw1"] = "减辎疾行，挫敌军锐气。",
  ["$cuoruiw2"] = "外物当舍，摄敌为重。",
  ["~wulan"] = "蛮狗，尔敢杀我！",
}

return extension
