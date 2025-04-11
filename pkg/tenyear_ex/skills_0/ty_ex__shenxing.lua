local ty_ex__shenxing = fk.CreateSkill {
  name = "ty_ex__shenxing"
}

Fk:loadTranslationTable{
  ['ty_ex__shenxing'] = '慎行',
  ['#ty_ex__shenxing-draw'] = '慎行：你可以摸一张牌',
  ['#ty_ex__shenxing'] = '慎行：你可以弃置%arg张牌，摸一张牌',
  [':ty_ex__shenxing'] = '出牌阶段，你可以弃置X张牌，然后摸一张牌（X为你此阶段发动本技能次数，至多为2）。',
  ['$ty_ex__shenxing1'] = '谋而后动，行不容差。',
  ['$ty_ex__shenxing2'] = '谋略之道，需慎之又慎。',
}

local function card_num(skill)
  return math.min(2, skill.player:usedSkillTimes(ty_ex__shenxing.name, Player.HistoryPhase))
end

local function prompt(skill)
  local n = skill.player:usedSkillTimes(ty_ex__shenxing.name, Player.HistoryPhase)
  if n == 0 then
    return "#ty_ex__shenxing-draw"
  else
    return "#ty_ex__shenxing:::"..math.min(2, n)
  end
end

local function card_filter(skill, player, to_select, selected)
  return #selected < math.min(2, player:usedSkillTimes(ty_ex__shenxing.name, Player.HistoryPhase)) and not player:prohibitDiscard(Fk:getCardById(to_select))
end

local function on_use(skill, room, effect)
  local player = room:getPlayerById(effect.from)
  room:throwCard(effect.cards, ty_ex__shenxing.name, player, player)
  if not player.dead then
    player:drawCards(1, ty_ex__shenxing.name)
  end
end

ty_ex__shenxing:addEffect('active', {
  anim_type = "drawcard",
  card_num = card_num,
  target_num = 0,
  prompt = prompt,
  can_use = Util.TrueFunc,
  card_filter = card_filter,
  on_use = on_use,
})

return ty_ex__shenxing
