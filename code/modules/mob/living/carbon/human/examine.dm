/mob/living/carbon/human/examine(mob/user)
//this is very slightly better than it was because you can use it more places. still can't do \his[src] though.
	var/t_He = p_they(TRUE)
	var/t_he = p_they()
	var/t_His = p_their(TRUE)
	var/t_his = p_their()
	var/t_him = p_them()
	var/t_has = p_have()
	var/t_is = p_are()
	var/t_es = p_es()
	var/obscure_name
	var/list/obscured = check_obscured_slots()
	var/skipface = ((wear_mask?.flags_inv & HIDEFACE) || (head?.flags_inv & HIDEFACE))

	if(isliving(user))
		var/mob/living/L = user
		if(HAS_TRAIT(L, TRAIT_PROSOPAGNOSIA))
			obscure_name = TRUE

	. = list(span_info("This is <EM>[name]</EM>!"))

	if(user != src)
		if(!obscure_name && !skipface)
			var/face_name = get_face_name("")
			if(face_name)
				//if we have no guestbook, we just KNOW okay?
				var/known_name = user.mind?.guestbook ? user.mind.guestbook.get_known_name(user, src, face_name) : face_name
				if(known_name)
					. += "You know [t_him] as <EM>[known_name]</EM>."
				else
					. += "You don't recognize [t_him]. You can <B>Ctrl-Shift click</b> [t_him] to memorize their face."
			else
				. += "You can't see [t_his] face very well."
		else
			. += "You can't see [t_his] face very well."
	else
		. += "It's you, <EM>[real_name]</EM>."

	//uniform
	if(w_uniform && !(ITEM_SLOT_ICLOTHING in obscured))
		//accessory
		var/accessory_msg
		if(istype(w_uniform, /obj/item/clothing/under))
			var/obj/item/clothing/under/U = w_uniform
			if(U.attached_accessory)
				accessory_msg += " with [icon2html(U.attached_accessory, user)] \a [U.attached_accessory]"

		. += "[t_He] [t_is] wearing [w_uniform.get_examine_string(user)][accessory_msg]."
	//head
	if(head)
		. += "[t_He] [t_is] wearing [head.get_examine_string(user)] on [t_his] head."
	//suit/armor
	if(wear_suit)
		. += "[t_He] [t_is] wearing [wear_suit.get_examine_string(user)]."
		//suit/armor storage
		if(s_store && !(ITEM_SLOT_SUITSTORE in obscured))
			. += "[t_He] [t_is] carrying [s_store.get_examine_string(user)] on [t_his] [wear_suit.name]."
	//back
	if(back)
		. += "[t_He] [t_has] [back.get_examine_string(user)] on [t_his] back."

	//Hands
	for(var/obj/item/I in held_items)
		if(!(I.item_flags & ABSTRACT))
			. += "[t_He] [t_is] holding [I.get_examine_string(user)] in [t_his] [get_held_index_name(get_held_index_of_item(I))]."

	var/datum/component/forensics/FR = GetComponent(/datum/component/forensics)
	//gloves
	if(gloves && !(ITEM_SLOT_GLOVES in obscured))
		. += "[t_He] [t_has] [gloves.get_examine_string(user)] on [t_his] hands."
	else if(FR && length(FR.blood_DNA))
		if(num_hands)
			. += span_warning("[t_He] [t_has] [num_hands > 1 ? "" : "a"] blood-stained hand[num_hands > 1 ? "s" : ""]!")

	//handcuffed?

	//handcuffed?
	if(handcuffed)
		if(istype(handcuffed, /obj/item/restraints/handcuffs/cable))
			. += span_warning("[t_He] [t_is] [icon2html(handcuffed, user)] restrained with cable!")
		else
			. += span_warning("[t_He] [t_is] [icon2html(handcuffed, user)] handcuffed!")

	//belt
	if(belt)
		. += "[t_He] [t_has] [belt.get_examine_string(user)] about [t_his] waist."

	//shoes
	if(shoes && !(ITEM_SLOT_FEET in obscured))
		. += "[t_He] [t_is] wearing [shoes.get_examine_string(user)] on [t_his] feet."

	//mask
	if(wear_mask && !(ITEM_SLOT_MASK in obscured))
		. += "[t_He] [t_has] [wear_mask.get_examine_string(user)] on [t_his] face."

	if(wear_neck && !(ITEM_SLOT_NECK in obscured))
		. += "[t_He] [t_is] wearing [wear_neck.get_examine_string(user)] around [t_his] neck."

	//eyes
	if(!(ITEM_SLOT_EYES in obscured))
		if(glasses)
			. += "[t_He] [t_has] [glasses.get_examine_string(user)] covering [t_his] eyes."
		else if(HAS_TRAIT(src, TRAIT_CLOUDED))
			. += span_notice("[t_His] eyes are clouded in silver.")
		else if(HAS_TRAIT(src, TRAIT_PINPOINT_EYES))
			. += span_warning("[t_His] pupils have diliated to pinpricks.")

	//ears
	if(ears && !(ITEM_SLOT_EARS in obscured))
		. += "[t_He] [t_has] [ears.get_examine_string(user)] on [t_his] ears."

	//ID
	if(wear_id)
		. += "[t_He] [t_is] wearing [wear_id.get_examine_string(user)]."

	//Status effects
	var/list/status_examines = status_effect_examines()
	if (length(status_examines))
		. += status_examines

	//jitters
	switch(jitteriness)
		if(300 to INFINITY)
			. += span_boldwarning("[t_He] [t_is] convulsing violently!")
		if(200 to 300)
			. += span_warning("[t_He] [t_is] extremely jittery.")
		if(100 to 200)
			. += span_warning("[t_He] [t_is] twitching ever so slightly.")
		if(50 to 100)
			. += span_warning("[t_He] [t_is] flinching lightly")

	var/appears_dead = FALSE
	var/just_sleeping = FALSE

	if(stat == DEAD || (HAS_TRAIT(src, TRAIT_FAKEDEATH)))
		appears_dead = TRUE

		var/obj/item/clothing/glasses/G = get_item_by_slot(ITEM_SLOT_EYES)
		var/are_we_in_weekend_at_bernies = G?.tint && buckled && istype(buckled, /obj/vehicle/ridden/wheelchair)

		if(isliving(user) && (HAS_TRAIT(user, TRAIT_NAIVE) || are_we_in_weekend_at_bernies))
			just_sleeping = TRUE

		if(!just_sleeping)
			if(hellbound)
				. += span_warning("[t_His] soul seems to have been ripped out of [t_his] body. Revival is impossible.")
			. += ""
			if(getorgan(/obj/item/organ/brain) && !key && !get_ghost(FALSE, TRUE))
				. += span_deadsay("[t_He] [t_is] limp and unresponsive; there are no signs of life and [t_he] won't be coming back...")
			else
				. += span_deadsay("[t_He] [t_is] limp and unresponsive; there are no signs of life...")

//WSStaion Begin - Broken Bones

	var/list/splinted_stuff = list()
	for(var/obj/item/bodypart/B in bodyparts)
		if(B.bone_status == BONE_FLAG_SPLINTED)
			splinted_stuff += B.name
	if(splinted_stuff.len)
		. += "[span_warning("<B>[t_His] [english_list(splinted_stuff)] [splinted_stuff.len > 1 ? "are" : "is"] splinted!</B>")]\n"

	if(get_bodypart(BODY_ZONE_HEAD) && !getorgan(/obj/item/organ/brain))
		. += span_deadsay("It appears that [t_his] brain is missing...")

	var/temp = getBruteLoss() //no need to calculate each of these twice

	var/list/msg = list()

	var/list/missing = list(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	var/list/disabled = list()
	for(var/obj/item/bodypart/BP as anything in bodyparts)
		if(BP.bodypart_disabled)
			disabled += BP
		missing -= BP.body_zone
		if(BP.uses_integrity && (BP.integrity_loss-BP.integrity_ignored) > 0)
			if ((BP.integrity_loss-BP.integrity_ignored) > BP.max_damage*0.66)
				msg += "<B>[t_His] [BP.name] is [BP.heavy_integrity_msg]!</B>\n"
			else if (BP.integrity_loss-BP.integrity_ignored > BP.max_damage*0.33)
				msg += "[t_His] [BP.name] is [BP.medium_integrity_msg]!\n"
			else
				msg += "[t_His] [BP.name] is [BP.light_integrity_msg].\n"
		for(var/obj/item/I in BP.embedded_objects)
			if(I.isEmbedHarmless())
				msg += "<B>[t_He] [t_has] \a [icon2html(I, user)] [I] stuck to [t_his] [BP.name]!</B>\n"
			else
				msg += "<B>[t_He] [t_has] \a [icon2html(I, user)] [I] embedded in [t_his] [BP.name]!</B>\n"

	for(var/X in disabled)
		var/obj/item/bodypart/BP = X
		var/damage_text
		if(!(BP.get_damage(include_stamina = FALSE) >= BP.max_damage)) //Stamina is disabling the limb
			damage_text = "limp and lifeless"
		else
			damage_text = (BP.brute_dam >= BP.burn_dam) ? BP.heavy_brute_msg : BP.heavy_burn_msg
		msg += "<B>[capitalize(t_his)] [BP.name] is [damage_text]!</B>\n"

	//stores missing limbs
	var/l_limbs_missing = 0
	var/r_limbs_missing = 0
	for(var/t in missing)
		if(t==BODY_ZONE_HEAD)
			msg += "<span class='deadsay'><B>[t_His] [parse_zone(t)] is missing!</B><span class='warning'>\n"
			continue
		if(t == BODY_ZONE_L_ARM || t == BODY_ZONE_L_LEG)
			l_limbs_missing++
		else if(t == BODY_ZONE_R_ARM || t == BODY_ZONE_R_LEG)
			r_limbs_missing++

		msg += "<B>[capitalize(t_his)] [parse_zone(t)] is missing!</B>\n"

	if(l_limbs_missing >= 2 && r_limbs_missing == 0)
		msg += "[t_He] look[p_s()] all right now.\n"
	else if(l_limbs_missing == 0 && r_limbs_missing >= 2)
		msg += "[t_He] really keeps to the left.\n"
	else if(l_limbs_missing >= 2 && r_limbs_missing >= 2)
		msg += "[t_He] [p_do()]n't seem all there.\n"

	for(var/obj/item/bodypart/BP as anything in bodyparts)
		if(BP.limb_id != (dna.species.examine_limb_id ? dna.species.examine_limb_id : dna.species.id))
			msg += "[span_info("[t_He] [t_has] \an [BP.name].")]\n"

	if(!(user == src && src.hal_screwyhud == SCREWYHUD_HEALTHY)) //fake healthy
		if(temp)
			if(temp < 25)
				msg += "[t_He] [t_has] minor bruising.\n"
			else if(temp < 50)
				msg += "[t_He] [t_has] <b>moderate</b> bruising!\n"
			else
				msg += "<B>[t_He] [t_has] severe bruising!</B>\n"

		temp = getFireLoss()
		if(temp)
			if(temp < 25)
				msg += "[t_He] [t_has] minor burns.\n"
			else if (temp < 50)
				msg += "[t_He] [t_has] <b>moderate</b> burns!\n"
			else
				msg += "<B>[t_He] [t_has] severe burns!</B>\n"

		temp = getCloneLoss()
		if(temp)
			if(temp < 25)
				msg += "[t_He] [t_has] minor cellular damage.\n"
			else if(temp < 50)
				msg += "[t_He] [t_has] <b>moderate</b> cellular damage!\n"
			else
				msg += "<b>[t_He] [t_has] severe cellular damage!</b>\n"


	switch(fire_stacks)
		if(1 to INFINITY)
			msg += "[t_He] [t_is] covered in something flammable.\n"
		if(0)
			EMPTY_BLOCK_GUARD
		if(-15 to -1)
			msg += "[t_He] look[p_s()] a little soaked.\n"
		if(-20 to -15)
			msg += "[t_He] look[p_s()] completely sopping.\n"


	if(pulledby && pulledby.grab_state)
		msg += "[t_He] [t_is] restrained by [pulledby]'s grip.\n"

	if(nutrition < NUTRITION_LEVEL_STARVING - 50)
		msg += "[t_He] [t_is] severely malnourished.\n"
	switch(disgust)
		if(DISGUST_LEVEL_GROSS to DISGUST_LEVEL_VERYGROSS)
			msg += "[t_He] look[p_s()] a bit grossed out.\n"
		if(DISGUST_LEVEL_VERYGROSS to DISGUST_LEVEL_DISGUSTED)
			msg += "[t_He] look[p_s()] really grossed out.\n"
		if(DISGUST_LEVEL_DISGUSTED to INFINITY)
			msg += "[t_He] look[p_s()] extremely disgusted.\n"

	if(blood_volume < BLOOD_VOLUME_SAFE || skin_tone == "albino")
		msg += "[t_He] [t_has] pale skin.\n"


	if(LAZYLEN(get_bandaged_parts()))
		msg += "[t_He] [t_has] some dressed bleeding.\n"

	var/list/obj/item/bodypart/bleed_check = get_bleeding_parts(TRUE)
	if(LAZYLEN(bleed_check))
		if(reagents.has_reagent(/datum/reagent/toxin/heparin, needs_metabolizing = TRUE))
			msg += "<b>[t_He] [t_is] bleeding uncontrollably!</b>\n"
		else
			msg += "<B>[t_He] [t_is] bleeding!</B>\n"

	if(reagents.has_reagent(/datum/reagent/teslium, needs_metabolizing = TRUE))
		msg += "[t_He] [t_is] emitting a gentle blue glow!\n"

	if(islist(stun_absorption))
		for(var/i in stun_absorption)
			if(stun_absorption[i]["end_time"] > world.time && stun_absorption[i]["examine_message"])
				msg += "[t_He] [t_is][stun_absorption[i]["examine_message"]]\n"

	if(just_sleeping)
		msg += "[t_He] [t_is]n't responding to anything around [t_him] and seem[p_s()] to be asleep.\n"

	if(!appears_dead)
		if(drunkenness && !skipface) //Drunkenness
			switch(drunkenness)
				if(11 to 21)
					msg += "[t_He] [t_is] slightly flushed.\n"
				if(21.01 to 41) //.01s are used in case drunkenness ends up to be a small decimal
					msg += "[t_He] [t_is] flushed.\n"
				if(41.01 to 51)
					msg += "[t_He] [t_is] quite flushed and [t_his] breath smells of alcohol.\n"
				if(51.01 to 61)
					msg += "[t_He] [t_is] very flushed and [t_his] movements jerky, with breath reeking of alcohol.\n"
				if(61.01 to 91)
					msg += "[t_He] look[p_s()] like a drunken mess.\n"
				if(91.01 to INFINITY)
					msg += "[t_He] [t_is] a shitfaced, slobbering wreck.\n"

		if(src != user)
			if(HAS_TRAIT(user, TRAIT_EMPATH))
				if (a_intent != INTENT_HELP)
					msg += "[t_He] seem[p_s()] to be on guard.\n"
				if (getOxyLoss() >= 10)
					msg += "[t_He] seem[p_s()] winded.\n"
				if (getToxLoss() >= 10)
					msg += "[t_He] seem[p_s()] sickly.\n"
				var/datum/component/mood/mood = src.GetComponent(/datum/component/mood)
				if(mood.sanity <= SANITY_DISTURBED)
					msg += "[t_He] seem[p_s()] distressed.\n"
					SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "empath", /datum/mood_event/sad_empath, src)
				if (is_blind())
					msg += "[t_He] appear[p_s()] to be staring off into space.\n"
				if (HAS_TRAIT(src, TRAIT_DEAF))
					msg += "[t_He] appear[p_s()] to not be responding to noises.\n"

			msg += "</span>"

		switch(stat)
			if(UNCONSCIOUS, HARD_CRIT)
				msg += "[t_He] [t_is]n't responding to anything around [t_him] and seem[p_s()] to be asleep.\n"
			if(SOFT_CRIT)
				msg += "[t_He] [t_is] barely conscious.\n"
			if(CONSCIOUS)
				if(HAS_TRAIT(src, TRAIT_DUMB))
					msg += "[t_He] [t_has] a stupid expression on [t_his] face.\n"
		if(getorgan(/obj/item/organ/brain))
			if(ai_controller?.ai_status == AI_STATUS_ON)
				msg += "[span_deadsay("[t_He] do[t_es]n't appear to be [t_him]self.")]\n"
			if(!key)
				msg += "[span_deadsay("[t_He] [t_is] totally catatonic. The stresses of life in deep-space must have been too much for [t_him]. Any recovery is unlikely.")]\n"
			else if(!client)
				msg += "[span_warning("[t_He] [t_has] been suffering from SSD - Space Sleep Disorder - for [trunc(((world.time - lastclienttime) / (1 MINUTES)))] minutes. [t_He] may snap out of it at any time! Or maybe never. It's best to leave [t_him] be.")]\n"
	if (length(msg))
		. += span_warning("[msg.Join("")]")

	switch(mothdust) //WS edit - moth dust from hugging
		if(1 to 50)
			. += "[t_He] [t_is] a little dusty."
		if(51 to 150)
			. += "[t_He] [t_has] a layer of shimmering dust on [t_him]."
		if(151 to INFINITY)
			. += "<b>[t_He] [t_is] covered in glistening dust!</b>" //End WS edit

	var/trait_exam = common_trait_examine()
	if (!isnull(trait_exam))
		. += trait_exam

	var/traitstring = get_trait_string(see_all=FALSE)

	var/perpname = get_face_name(get_id_name(""))
	if(perpname && (HAS_TRAIT(user, TRAIT_SECURITY_HUD) || HAS_TRAIT(user, TRAIT_MEDICAL_HUD)))
		var/datum/data/record/R = find_record("name", perpname, GLOB.data_core.general)
		if(R)
			. += "[span_deptradio("Rank:")] [R.fields["rank"]]\n<a href='byond://?src=[REF(src)];hud=1;photo_front=1'>\[Front photo\]</a><a href='byond://?src=[REF(src)];hud=1;photo_side=1'>\[Side photo\]</a>"
		if(HAS_TRAIT(user, TRAIT_MEDICAL_HUD))
			var/cyberimp_detect
			for(var/obj/item/organ/cyberimp/CI in internal_organs)
				if(CI.status == ORGAN_ROBOTIC && !CI.syndicate_implant)
					cyberimp_detect += "[!cyberimp_detect ? "[CI.get_examine_string(user)]" : ", [CI.get_examine_string(user)]"]"
			if(cyberimp_detect)
				. += "<span class='notice ml-1'>Detected cybernetic modifications:</span>"
				. += "<span class='notice ml-2'>[cyberimp_detect]</span>"
			if(R)
				var/health_r = R.fields["p_stat"]
				. += "<a href='byond://?src=[REF(src)];hud=m;p_stat=1'>\[[health_r]\]</a>"
				health_r = R.fields["m_stat"]
				. += "<a href='byond://?src=[REF(src)];hud=m;m_stat=1'>\[[health_r]\]</a>"
			R = find_record("name", perpname, GLOB.data_core.medical)
			if(R)
				. += "<a href='byond://?src=[REF(src)];hud=m;evaluation=1'>\[Medical evaluation\]</a><br>"
			if(traitstring)
				. += "<span class='notice ml-1'>Detected physiological traits:</span>"
				. += "<span class='notice ml-2'>[traitstring]</span>"

		if(HAS_TRAIT(user, TRAIT_SECURITY_HUD))
			if(!user.stat && user != src)
			//|| !user.canmove || user.restrained()) Fluff: Sechuds have eye-tracking technology and sets 'arrest' to people that the wearer looks and blinks at.
				var/criminal = "None"

				R = find_record("name", perpname, GLOB.data_core.security)
				if(R)
					criminal = R.fields["criminal"]

				. += "[span_deptradio("Criminal status:")] <a href='byond://?src=[REF(src)];hud=s;status=1'>\[[criminal]\]</a>"
				. += jointext(list("[span_deptradio("Security record:")] <a href='byond://?src=[REF(src)];hud=s;view=1'>\[View\]</a>",
					"<a href='byond://?src=[REF(src)];hud=s;add_crime=1'>\[Add crime\]</a>",
					"<a href='byond://?src=[REF(src)];hud=s;view_comment=1'>\[View comment log\]</a>",
					"<a href='byond://?src=[REF(src)];hud=s;add_comment=1'>\[Add comment\]</a>"), "")
	else if(isobserver(user) && traitstring)
		. += span_info("<b>Traits:</b> [traitstring]")

	//No flavor text unless the face can be seen. Prevents certain metagaming with impersonation.
	var/invisible_man = skipface || get_visible_name() == "Unknown"
	if(invisible_man)
		. += "...?"
	else
		var/flavor = print_flavor_text()
		if(flavor)
			. += flavor
	. += "*---------*</span>"

	SEND_SIGNAL(src, COMSIG_PARENT_EXAMINE, user, .)

/mob/living/proc/status_effect_examines(pronoun_replacement) //You can include this in any mob's examine() to show the examine texts of status effects!
	var/list/dat = list()
	if(!pronoun_replacement)
		pronoun_replacement = p_they(TRUE)
	for(var/V in status_effects)
		var/datum/status_effect/E = V
		if(E.examine_text)
			var/new_text = replacetext(E.examine_text, "SUBJECTPRONOUN", pronoun_replacement)
			new_text = replacetext(new_text, "[pronoun_replacement] is", "[pronoun_replacement] [p_are()]") //To make sure something become "They are" or "She is", not "They are" and "She are"
			dat += "[new_text]\n" //dat.Join("\n") doesn't work here, for some reason
	if(dat.len)
		return dat.Join()

/mob/living/carbon/human/examine_more(mob/user)
	. = ..()
	for(var/obj/item/bodypart/BP as anything in get_bandaged_parts())
		var/datum/component/bandage/B = BP.GetComponent(/datum/component/bandage)
		. += span_notice("[p_their(TRUE)] [parse_zone(BP.body_zone)] is dressed with [B.bandage_name]")
	for(var/obj/item/bodypart/BP as anything in get_bleeding_parts(TRUE))
		var/bleed_text
		switch(BP.bleeding)
			if(0 to 0.5)
				bleed_text = "lightly."
			if(0.5 to 1)
				bleed_text = "moderately."
			if(1 to 1.5)
				bleed_text = "heavily!"
			else
				bleed_text = "significantly!!"
		. += span_warning("[p_their(TRUE)] [parse_zone(BP.body_zone)] is bleeding [bleed_text]")

	if ((wear_mask && (wear_mask.flags_inv & HIDEFACE)) || (head && (head.flags_inv & HIDEFACE)))
		return
	if(get_age())
		. += span_notice("[p_they(TRUE)] appear[p_s()] to be [get_age()].")
