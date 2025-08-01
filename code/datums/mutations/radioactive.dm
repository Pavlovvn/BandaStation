/datum/mutation/radioactive
	name = "Radioactivity"
	desc = "Нестабильная мутация, которая заставляет носителя излучать смертельные бета-частицы. Мутация влияет на носителя и его окружение."
	quality = NEGATIVE
	text_gain_indication = span_warning("Ты ощущаешь, как что-то проходит через твои клетки и кости!")
	instability = NEGATIVE_STABILITY_MAJOR
	difficulty = 8
	power_coeff = 1
	/// Weakref to our radiation emitter component
	var/datum/weakref/radioactivity_source_ref

/datum/mutation/radioactive/New(datum/mutation/copymut)
	. = ..()
	if(!(type in visual_indicators))
		visual_indicators[type] = list(mutable_appearance('icons/mob/effects/genetics.dmi', "radiation", -MUTATIONS_LAYER))

/datum/mutation/radioactive/get_visual_indicator()
	return visual_indicators[type][1]

/datum/mutation/radioactive/on_acquiring(mob/living/carbon/human/acquirer)
	. = ..()
	if(!.)
		return
	var/datum/component/radioactive_emitter/radioactivity_source = make_radioactive(acquirer)
	radioactivity_source_ref = WEAKREF(radioactivity_source)

/datum/mutation/radioactive/setup()
	. = ..()
	if(!QDELETED(owner))
		make_radioactive(owner)

/**
 * Makes the passed mob radioactive, or if they're already radioactive,
 * update their radioactivity to the newly set values
 */
/datum/mutation/radioactive/proc/make_radioactive(mob/living/carbon/human/who)
	return who.AddComponent(
		/datum/component/radioactive_emitter, \
		cooldown_time = 5 SECONDS, \
		range = 1 * (GET_MUTATION_POWER(src) * 2), \
		threshold = RAD_MEDIUM_INSULATION, \
	)

/datum/mutation/radioactive/on_losing(mob/living/carbon/human/owner)
	QDEL_NULL(radioactivity_source_ref)
	return ..()
