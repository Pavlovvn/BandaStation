// Ritual spells which affect the station at large
/// How much threat we need to let these rituals happen on dynamic
#define MINIMUM_THREAT_FOR_RITUALS 98

/datum/spellbook_entry/summon/ghosts
	name = "Summon Ghosts"
	desc = "Напугайте экипаж, заставив их видеть мертвых. \
		Будьте внимательны, призраки капризны и иногда мстительны, \
		а некоторые из них будут использовать свои невероятно незначительные способности, чтобы насолить вам."
	cost = 0

/datum/spellbook_entry/summon/ghosts/buy_spell(mob/living/carbon/human/user, obj/item/spellbook/book, log_buy = TRUE)
	summon_ghosts(user)
	playsound(get_turf(user), 'sound/effects/ghost2.ogg', 50, TRUE)
	return ..()

/datum/spellbook_entry/summon/guns
	name = "Summon Guns"
	desc = "Нет ничего плохого в том, чтобы вооружить команду сумасшедших, которые только и ждут повода, чтобы убить вас. \
		Но велика вероятность, что они сперва перестреляют друг друга."

/datum/spellbook_entry/summon/guns/can_be_purchased()
	// Must be a high chaos round + Also must be config enabled
	return SSdynamic.current_tier.tier == DYNAMIC_TIER_HIGH && !CONFIG_GET(flag/no_summon_guns)

/datum/spellbook_entry/summon/guns/buy_spell(mob/living/carbon/human/user, obj/item/spellbook/book, log_buy = TRUE)
	summon_guns(user, 10)
	playsound(get_turf(user), 'sound/effects/magic/castsummon.ogg', 50, TRUE)
	return ..()

/datum/spellbook_entry/summon/magic
	name = "Summon Magic"
	desc = "Поделитесь с командой чудесами магии \
		и заодно покажите им, почему им нельзя ее доверять."

/datum/spellbook_entry/summon/magic/can_be_purchased()
	// Must be a high chaos round + Also must be config enabled
	return SSdynamic.current_tier.tier == DYNAMIC_TIER_HIGH && !CONFIG_GET(flag/no_summon_magic)

/datum/spellbook_entry/summon/magic/buy_spell(mob/living/carbon/human/user, obj/item/spellbook/book, log_buy = TRUE)
	summon_magic(user, 10)
	playsound(get_turf(user), 'sound/effects/magic/castsummon.ogg', 50, TRUE)
	return ..()

/datum/spellbook_entry/summon/events
	name = "Summon Events"
	desc = "Подтолкните закон Мерфи и замените все события на  \
		специальные магические, которые запутают и собьют с толку всех. \
		Многократное использование увеличивает частоту этих событий."
	cost = 2
	limit = 5 // Each purchase can intensify it.

/datum/spellbook_entry/summon/events/can_be_purchased()
	// Must be a high chaos round + Also must be config enabled
	return SSdynamic.current_tier.tier == DYNAMIC_TIER_HIGH && !CONFIG_GET(flag/no_summon_events)

/datum/spellbook_entry/summon/events/buy_spell(mob/living/carbon/human/user, obj/item/spellbook/book, log_buy = TRUE)
	summon_events(user)
	playsound(get_turf(user), 'sound/effects/magic/castsummon.ogg', 50, TRUE)
	return ..()

/datum/spellbook_entry/summon/curse_of_madness
	name = "Curse of Madness"
	desc = "Проклинает станцию, искажая сознание всех, кто в ней находится, и вызывая неизгладимые травмы. Предупреждение: это заклинание может подействовать на вас, если оно не применяется с безопасного расстояния."
	cost = 4

/datum/spellbook_entry/summon/curse_of_madness/buy_spell(mob/living/carbon/human/user, obj/item/spellbook/book, log_buy = TRUE)
	var/message = tgui_input_text(user, "Прошепчите секретную истину, чтобы довести ваших жертв до безумия", "Шепоты безумия", max_length = MAX_MESSAGE_LEN)
	if(!message || QDELETED(user) || QDELETED(book) || !can_buy(user, book))
		return FALSE
	curse_of_madness(user, message)
	playsound(user, 'sound/effects/magic/mandswap.ogg', 50, TRUE)
	return ..()

/// A wizard ritual that allows the wizard to teach a specific spellbook enty to everyone on the station.
/// This includes item entries (which will be given to everyone) but disincludes other rituals like itself
/datum/spellbook_entry/summon/specific_spell
	name = "Mass Wizard Teaching"
	desc = "Научите определенному заклинанию (или дайте определенный предмет) каждому на станции. \
		Стоимость этого увеличивается на стоимость выбранного вами заклинания. И не волнуйтесь - вы тоже выучите заклинание!"
	cost = 3 // cheapest is 4 cost, most expensive is 7 cost
	limit = 1

/datum/spellbook_entry/summon/specific_spell/buy_spell(mob/living/carbon/human/user, obj/item/spellbook/book, log_buy = TRUE)
	var/list/spell_options = list()
	for(var/datum/spellbook_entry/entry as anything in book.entries)
		if(istype(entry, /datum/spellbook_entry/summon))
			continue
		if(!entry.can_be_purchased())
			continue

		spell_options[entry.name] = entry

	sortTim(spell_options, GLOBAL_PROC_REF(cmp_text_asc))
	var/chosen_spell_name = tgui_input_list(user, "Выберите заклинание (или предмет), которое вы дадите каждому...", "Волшебное обучение", spell_options)
	if(isnull(chosen_spell_name) || QDELETED(user) || QDELETED(book))
		return FALSE
	if(GLOB.mass_teaching)
		tgui_alert(user, "Кто-то уже провел [name]!", "Волшебное обучение", list("Shame"))
		return FALSE

	var/datum/spellbook_entry/chosen_entry = spell_options[chosen_spell_name]
	if(cost + chosen_entry.cost > book.uses)
		tgui_alert(user, "Вы не можете позволить себе предоставить всем [chosen_spell_name]! (нужно [cost] очков)", "Волшебное обучение", list("Shame"))
		return FALSE

	cost += chosen_entry.cost
	if(!can_buy(user, book))
		cost = initial(cost)
		return FALSE

	GLOB.mass_teaching = new(chosen_entry.type)
	GLOB.mass_teaching.equip_all_affected()

	var/item_entry = istype(chosen_entry, /datum/spellbook_entry/item)
	to_chat(user, span_hypnophrase("Вы [item_entry ? "даровали всем силу" : "обучили всех приемами"] [chosen_spell_name]!"))
	message_admins("[ADMIN_LOOKUPFLW(user)] gave everyone the [item_entry ? "item" : "spell"] \"[chosen_spell_name]\"!")
	user.log_message("has gave everyone the [item_entry ? "item" : "spell"] \"[chosen_spell_name]\"!", LOG_GAME)

	name = "[name]: [chosen_spell_name]"
	return ..()

/datum/spellbook_entry/summon/specific_spell/can_buy(mob/living/carbon/human/user, obj/item/spellbook/book)
	if(GLOB.mass_teaching)
		return FALSE
	return ..()

/datum/spellbook_entry/summon/specific_spell/can_be_purchased()
	if(SSdynamic.current_tier.tier != DYNAMIC_TIER_HIGH)
		return FALSE
	if(GLOB.mass_teaching)
		return FALSE
	return ..()

#undef MINIMUM_THREAT_FOR_RITUALS
