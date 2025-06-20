////////////////////////////////
///// Construction datums //////
////////////////////////////////
/datum/component/construction/mecha
	var/base_icon
	// if we need to override the icon for a different one from the base. Step determines when the override occurs.
	var/override_icon
	var/override_step = list()

	// Component typepaths.
	// most must be defined unless
	// get_steps is overriden.

	// Circuit board typepaths.
	// circuit_control and circuit_periph must be defined
	// unless get_circuit_steps is overriden.
	var/circuit_control
	var/circuit_periph
	var/circuit_weapon

	// Armor plating typepaths. both must be defined
	// unless relevant step procs are overriden. amounts
	// must be defined if using /obj/item/stack/sheet types
	var/inner_plating
	var/inner_plating_amount

	var/outer_plating
	var/outer_plating_amount

/datum/component/construction/mecha/spawn_result()
	if(!result)
		return
	// Remove default mech power cell, as we replace it with a new one.
	var/obj/mecha/M = new result(drop_location())
	QDEL_NULL(M.cell)
	QDEL_NULL(M.scanmod)
	QDEL_NULL(M.capacitor)

	var/obj/item/mecha_parts/chassis/parent_chassis = parent
	M.CheckParts(parent_chassis.contents)

	SSblackbox.record_feedback("tally", "mechas_created", 1, M.name)
	QDEL_NULL(parent)

// Default proc to generate mech steps.
// Override if the mech needs an entirely custom process (See HONK mech)
// Otherwise override specific steps as needed (Ripley, firefighter, Phazon)
/datum/component/construction/mecha/proc/get_steps()
	return get_frame_steps() + get_circuit_steps() + (circuit_weapon ? get_circuit_weapon_steps() : list()) + get_stockpart_steps() + get_inner_plating_steps() + get_outer_plating_steps()

/datum/component/construction/mecha/update_parent(step_index)
	steps = get_steps()
	..()
	// By default, each step in mech construction has a single icon_state:
	// "[base_icon][index - 1]"
	// For example, Ripley's step 1 icon_state is "ripley0".
	var/atom/parent_atom = parent
	if(override_icon && ((index-1) in override_step))
		if(!steps[index]["icon_state"] && base_icon)
			parent_atom.icon_state = "[override_icon][index - 1]"
			return

	if(!steps[index]["icon_state"] && base_icon)
		parent_atom.icon_state = "[base_icon][index - 1]"

/datum/component/construction/unordered/mecha_chassis/custom_action(obj/item/I, mob/living/user, typepath)
	. = user.transferItemToLoc(I, parent)
	if(.)
		var/atom/parent_atom = parent
		user.visible_message(span_notice("[user] connects [I] to [parent]."), span_notice("You connect [I] to [parent]."))
		parent_atom.add_overlay(I.icon_state+"+o")
		qdel(I)

/datum/component/construction/unordered/mecha_chassis/spawn_result()
	var/atom/parent_atom = parent
	parent_atom.icon = 'icons/mecha/mech_construction.dmi'
	parent_atom.density = TRUE
	parent_atom.cut_overlays()
	..()

// Default proc for the first steps of mech construction.
/datum/component/construction/mecha/proc/get_frame_steps()
	return list(
		list(
			"key" = TOOL_WRENCH,
			"desc" = "The hydraulic systems are disconnected."
		),
		list(
			"key" = TOOL_SCREWDRIVER,
			"back_key" = TOOL_WRENCH,
			"desc" = "The hydraulic systems are connected."
		),
		list(
			"key" = /obj/item/stack/cable_coil,
			"amount" = 5,
			"back_key" = TOOL_SCREWDRIVER,
			"desc" = "The hydraulic systems are active."
		),
		list(
			"key" = TOOL_WIRECUTTER,
			"back_key" = TOOL_SCREWDRIVER,
			"desc" = "The wiring is added."
		)
	)

// Default proc for the circuit board steps of a mech.
// Second set of steps by default.
/datum/component/construction/mecha/proc/get_circuit_steps()
	return list(
		list(
			"key" = circuit_control,
			"action" = ITEM_DELETE,
			"back_key" = TOOL_SCREWDRIVER,
			"desc" = "The wiring is adjusted."
		),
		list(
			"key" = TOOL_SCREWDRIVER,
			"back_key" = TOOL_CROWBAR,
			"desc" = "Central control module is installed."
		),
		list(
			"key" = circuit_periph,
			"action" = ITEM_DELETE,
			"back_key" = TOOL_SCREWDRIVER,
			"desc" = "Central control module is secured."
		),
		list(
			"key" = TOOL_SCREWDRIVER,
			"back_key" = TOOL_CROWBAR,
			"desc" = "Peripherals control module is installed."
		)
	)

// Default proc for weapon circuitboard steps
// Used by combat mechs
/datum/component/construction/mecha/proc/get_circuit_weapon_steps()
	return list(
		list(
			"key" = circuit_weapon,
			"action" = ITEM_DELETE,
			"back_key" = TOOL_SCREWDRIVER,
			"desc" = "Peripherals control module is secured."
		),
		list(
			"key" = TOOL_SCREWDRIVER,
			"back_key" = TOOL_CROWBAR,
			"desc" = "Weapons control module is installed."
		)
	)

// Default proc for stock part installation
// Third set of steps by default
/datum/component/construction/mecha/proc/get_stockpart_steps()
	var/prevstep_text = circuit_weapon ? "Weapons control module is secured." : "Peripherals control module is secured."
	return list(
		list(
			"key" = /obj/item/stock_parts/scanning_module,
			"action" = ITEM_MOVE_INSIDE,
			"back_key" = TOOL_SCREWDRIVER,
			"desc" = prevstep_text
		),
		list(
			"key" = TOOL_SCREWDRIVER,
			"back_key" = TOOL_CROWBAR,
			"desc" = "Scanner module is installed."
		),
		list(
			"key" = /obj/item/stock_parts/capacitor,
			"action" = ITEM_MOVE_INSIDE,
			"back_key" = TOOL_SCREWDRIVER,
			"desc" = "Scanner module is secured."
		),
		list(
			"key" = TOOL_SCREWDRIVER,
			"back_key" = TOOL_CROWBAR,
			"desc" = "Capacitor is installed."
		),
		list(
			"key" = /obj/item/stock_parts/cell,
			"action" = ITEM_MOVE_INSIDE,
			"back_key" = TOOL_SCREWDRIVER,
			"desc" = "Capacitor is secured."
		),
		list(
			"key" = TOOL_SCREWDRIVER,
			"back_key" = TOOL_CROWBAR,
			"desc" = "The power cell is installed."
		)
	)

// Default proc for inner armor plating
// Fourth set of steps by default
/datum/component/construction/mecha/proc/get_inner_plating_steps()
	var/list/first_step
	if(ispath(inner_plating, /obj/item/stack/sheet))
		first_step = list(
			list(
				"key" = inner_plating,
				"amount" = inner_plating_amount,
				"back_key" = TOOL_SCREWDRIVER,
				"desc" = "The power cell is secured."
			)
		)
	else
		first_step = list(
			list(
				"key" = inner_plating,
				"action" = ITEM_DELETE,
				"back_key" = TOOL_SCREWDRIVER,
				"desc" = "The power cell is secured."
			)
		)

	return first_step + list(
		list(
			"key" = TOOL_WRENCH,
			"back_key" = TOOL_CROWBAR,
			"desc" = "Inner plating is installed."
		),
		list(
			"key" = TOOL_WELDER,
			"back_key" = TOOL_WRENCH,
			"desc" = "Inner Plating is wrenched."
		)
	)

// Default proc for outer armor plating
// Fifth set of steps by default
/datum/component/construction/mecha/proc/get_outer_plating_steps()
	var/list/first_step
	if(ispath(outer_plating, /obj/item/stack/sheet))
		first_step = list(
			list(
				"key" = outer_plating,
				"amount" = outer_plating_amount,
				"back_key" = TOOL_WELDER,
				"desc" = "Inner plating is welded."
			)
		)
	else
		first_step = list(
			list(
				"key" = outer_plating,
				"action" = ITEM_DELETE,
				"back_key" = TOOL_WELDER,
				"desc" = "Inner plating is welded."
			)
		)

	return first_step + list(
		list(
			"key" = TOOL_WRENCH,
			"back_key" = TOOL_CROWBAR,
			"desc" = "External armor is installed."
		),
		list(
			"key" = TOOL_WELDER,
			"back_key" = TOOL_WRENCH,
			"desc" = "External armor is wrenched."
		)
	)


/datum/component/construction/unordered/mecha_chassis/ripley
	result = /datum/component/construction/mecha/ripley
	steps = list(
		/obj/item/mecha_parts/part/ripley_torso,
		/obj/item/mecha_parts/part/ripley_left_arm,
		/obj/item/mecha_parts/part/ripley_right_arm,
		/obj/item/mecha_parts/part/ripley_left_leg,
		/obj/item/mecha_parts/part/ripley_right_leg
	)

/datum/component/construction/mecha/ripley
	result = /obj/mecha/working/ripley
	base_icon = "ripley"

	circuit_control = /obj/item/circuitboard/mecha/ripley/main
	circuit_periph = /obj/item/circuitboard/mecha/ripley/peripherals

	inner_plating=/obj/item/stack/sheet/metal
	inner_plating_amount = 5

	outer_plating=/obj/item/stack/rods
	outer_plating_amount = 10

/datum/component/construction/mecha/ripley/get_outer_plating_steps()
	return list(
		list(
			"key" = /obj/item/stack/rods,
			"amount" = 10,
			"back_key" = TOOL_WELDER,
			"desc" = "Outer Plating is welded."
		),
		list(
			"key" = TOOL_WELDER,
			"back_key" = TOOL_WIRECUTTER,
			"desc" = "Cockpit wire screen is installed."
		),
	)

/datum/component/construction/mecha/ripley/custom_action(obj/item/I, mob/living/user, diff)
	if(!..())
		return FALSE

	switch(index)
		if(1)
			user.visible_message(span_notice("[user] connects [parent] hydraulic systems."), span_notice("You connect [parent] hydraulic systems."))
		if(2)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] activates [parent] hydraulic systems."), span_notice("You activate [parent] hydraulic systems."))
			else
				user.visible_message(span_notice("[user] disconnects [parent] hydraulic systems."), span_notice("You disconnect [parent] hydraulic systems."))
		if(3)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] adds the wiring to [parent]."), span_notice("You add the wiring to [parent]."))
			else
				user.visible_message(span_notice("[user] deactivates [parent] hydraulic systems."), span_notice("You deactivate [parent] hydraulic systems."))
		if(4)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] adjusts the wiring of [parent]."), span_notice("You adjust the wiring of [parent]."))
			else
				user.visible_message(span_notice("[user] removes the wiring from [parent]."), span_notice("You remove the wiring from [parent]."))
		if(5)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] disconnects the wiring of [parent]."), span_notice("You disconnect the wiring of [parent]."))
		if(6)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the mainboard."), span_notice("You secure the mainboard."))
			else
				user.visible_message(span_notice("[user] removes the central control module from [parent]."), span_notice("You remove the central computer mainboard from [parent]."))
		if(7)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the mainboard."), span_notice("You unfasten the mainboard."))
		if(8)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the peripherals control module."), span_notice("You secure the peripherals control module."))
			else
				user.visible_message(span_notice("[user] removes the peripherals control module from [parent]."), span_notice("You remove the peripherals control module from [parent]."))
		if(9)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the peripherals control module."), span_notice("You unfasten the peripherals control module."))
		if(10)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the scanner module."), span_notice("You secure the scanner module."))
			else
				user.visible_message(span_notice("[user] removes the scanner module from [parent]."), span_notice("You remove the scanner module from [parent]."))
		if(11)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] to [parent]."), span_notice("You install [I] to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the scanner module."), span_notice("You unfasten the scanner module."))
		if(12)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures [I]."), span_notice("You secure [I]."))
			else
				user.visible_message(span_notice("[user] removes the capacitor from [parent]."), span_notice("You remove the capacitor from [parent]."))
		if(13)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I]."), span_notice("You install [I]."))
			else
				user.visible_message(span_notice("[user] unsecures the capacitor from [parent]."), span_notice("You unsecure the capacitor from [parent]."))
		if(14)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the power cell."), span_notice("You secure the power cell."))
			else
				user.visible_message(span_notice("[user] pries the power cell from [parent]."), span_notice("You pry the power cell from [parent]."))
		if(15)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs the internal armor layer to [parent]."), span_notice("You install the internal armor layer to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the power cell."), span_notice("You unfasten the power cell."))
		if(16)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the internal armor layer."), span_notice("You secure the internal armor layer."))
			else
				user.visible_message(span_notice("[user] pries internal armor layer from [parent]."), span_notice("You pry internal armor layer from [parent]."))
		if(17)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] welds the internal armor layer to [parent]."), span_notice("You weld the internal armor layer to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the internal armor layer."), span_notice("You unfasten the internal armor layer."))
		if(18)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs the external reinforced armor layer to [parent]."), span_notice("You install the external reinforced armor layer to [parent]."))
			else
				user.visible_message(span_notice("[user] cuts the internal armor layer from [parent]."), span_notice("You cut the internal armor layer from [parent]."))
		if(19)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the external armor layer."), span_notice("You secure the external reinforced armor layer."))
			else
				user.visible_message(span_notice("[user] pries external armor layer from [parent]."), span_notice("You pry external armor layer from [parent]."))
		if(20)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] welds the external armor layer to [parent]."), span_notice("You weld the external armor layer to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the external armor layer."), span_notice("You unfasten the external armor layer."))
	return TRUE

/datum/component/construction/unordered/mecha_chassis/gygax
	result = /datum/component/construction/mecha/gygax
	steps = list(
		/obj/item/mecha_parts/part/gygax_torso,
		/obj/item/mecha_parts/part/gygax_left_arm,
		/obj/item/mecha_parts/part/gygax_right_arm,
		/obj/item/mecha_parts/part/gygax_left_leg,
		/obj/item/mecha_parts/part/gygax_right_leg,
		/obj/item/mecha_parts/part/gygax_head
	)

/datum/component/construction/mecha/gygax
	result = /obj/mecha/combat/gygax
	base_icon = "gygax"

	circuit_control = /obj/item/circuitboard/mecha/gygax/main
	circuit_periph = /obj/item/circuitboard/mecha/gygax/peripherals
	circuit_weapon = /obj/item/circuitboard/mecha/gygax/targeting

	inner_plating = /obj/item/stack/sheet/metal
	inner_plating_amount = 5

	outer_plating=/obj/item/mecha_parts/part/gygax_armor
	outer_plating_amount=1

/datum/component/construction/unordered/mecha_chassis/mpgygax
	result = /datum/component/construction/mecha/gygax/mp
	steps = list(
		/obj/item/mecha_parts/part/gygax_torso,
		/obj/item/mecha_parts/part/gygax_left_arm,
		/obj/item/mecha_parts/part/gygax_right_arm,
		/obj/item/mecha_parts/part/gygax_left_leg,
		/obj/item/mecha_parts/part/gygax_right_leg,
		/obj/item/mecha_parts/part/gygax_head
	)

/datum/component/construction/mecha/gygax/mp
	result = /obj/mecha/combat/gygax/charger/mp

	outer_plating = /obj/item/mecha_parts/part/mpgygax_armor
	override_icon = "mpgygax"
	override_step = list(21,22)

/datum/component/construction/mecha/gygax/action(datum/source, atom/used_atom, mob/user)
	return INVOKE_ASYNC(src, PROC_REF(check_step), used_atom, user)

/datum/component/construction/mecha/gygax/custom_action(obj/item/I, mob/living/user, diff)
	if(!..())
		return FALSE

	switch(index)
		if(1)
			user.visible_message(span_notice("[user] connects [parent] hydraulic systems."), span_notice("You connect [parent] hydraulic systems."))
		if(2)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] activates [parent] hydraulic systems."), span_notice("You activate [parent] hydraulic systems."))
			else
				user.visible_message(span_notice("[user] disconnects [parent] hydraulic systems."), span_notice("You disconnect [parent] hydraulic systems."))
		if(3)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] adds the wiring to [parent]."), span_notice("You add the wiring to [parent]."))
			else
				user.visible_message(span_notice("[user] deactivates [parent] hydraulic systems."), span_notice("You deactivate [parent] hydraulic systems."))
		if(4)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] adjusts the wiring of [parent]."), span_notice("You adjust the wiring of [parent]."))
			else
				user.visible_message(span_notice("[user] removes the wiring from [parent]."), span_notice("You remove the wiring from [parent]."))
		if(5)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] disconnects the wiring of [parent]."), span_notice("You disconnect the wiring of [parent]."))
		if(6)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the mainboard."), span_notice("You secure the mainboard."))
			else
				user.visible_message(span_notice("[user] removes the central control module from [parent]."), span_notice("You remove the central computer mainboard from [parent]."))
		if(7)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the mainboard."), span_notice("You unfasten the mainboard."))
		if(8)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the peripherals control module."), span_notice("You secure the peripherals control module."))
			else
				user.visible_message(span_notice("[user] removes the peripherals control module from [parent]."), span_notice("You remove the peripherals control module from [parent]."))
		if(9)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the peripherals control module."), span_notice("You unfasten the peripherals control module."))
		if(10)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the weapon control module."), span_notice("You secure the weapon control module."))
			else
				user.visible_message(span_notice("[user] removes the weapon control module from [parent]."), span_notice("You remove the weapon control module from [parent]."))
		if(11)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] to [parent]."), span_notice("You install [I] to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the weapon control module."), span_notice("You unfasten the weapon control module."))
		if(12)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the scanner module."), span_notice("You secure the scanner module."))
			else
				user.visible_message(span_notice("[user] removes the scanner module from [parent]."), span_notice("You remove the scanner module from [parent]."))
		if(13)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] to [parent]."), span_notice("You install [I] to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the scanner module."), span_notice("You unfasten the scanner module."))
		if(14)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the capacitor."), span_notice("You secure the capacitor."))
			else
				user.visible_message(span_notice("[user] removes the capacitor from [parent]."), span_notice("You remove the capacitor from [parent]."))
		if(15)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the capacitor."), span_notice("You unfasten the capacitor."))
		if(16)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the power cell."), span_notice("You secure the power cell."))
			else
				user.visible_message(span_notice("[user] pries the power cell from [parent]."), span_notice("You pry the power cell from [parent]."))
		if(17)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs the internal armor layer to [parent]."), span_notice("You install the internal armor layer to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the power cell."), span_notice("You unfasten the power cell."))
		if(18)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the internal armor layer."), span_notice("You secure the internal armor layer."))
			else
				user.visible_message(span_notice("[user] pries internal armor layer from [parent]."), span_notice("You pry internal armor layer from [parent]."))
		if(19)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] welds the internal armor layer to [parent]."), span_notice("You weld the internal armor layer to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the internal armor layer."), span_notice("You unfasten the internal armor layer."))
		if(20)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] to [parent]."), span_notice("You install [I] to [parent]."))
			else
				user.visible_message(span_notice("[user] cuts the internal armor layer from [parent]."), span_notice("You cut the internal armor layer from [parent]."))
		if(21)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the armor plates."), span_notice("You secure the armor plates."))
			else
				user.visible_message(span_notice("[user] pries the armor plates from [parent]."), span_notice("You pry the armor plates from [parent]."))
		if(22)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] welds the armor plates to [parent]."), span_notice("You weld the armor plates to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the armor plates."), span_notice("You unfasten the armor plates."))
	return TRUE

/datum/component/construction/unordered/mecha_chassis/firefighter
	result = /datum/component/construction/mecha/firefighter
	steps = list(
		/obj/item/mecha_parts/part/ripley_torso,
		/obj/item/mecha_parts/part/ripley_left_arm,
		/obj/item/mecha_parts/part/ripley_right_arm,
		/obj/item/mecha_parts/part/ripley_left_leg,
		/obj/item/mecha_parts/part/ripley_right_leg,
		/obj/item/clothing/suit/fire
	)

/datum/component/construction/mecha/firefighter
	result = /obj/mecha/working/ripley/firefighter
	base_icon = "fireripley"

	circuit_control = /obj/item/circuitboard/mecha/ripley/main
	circuit_periph = /obj/item/circuitboard/mecha/ripley/peripherals

	inner_plating = /obj/item/stack/sheet/plasteel
	inner_plating_amount = 5

/datum/component/construction/mecha/firefighter/get_outer_plating_steps()
	return list(
		list(
			"key" = /obj/item/stack/sheet/plasteel,
			"amount" = 5,
			"back_key" = TOOL_WELDER,
			"desc" = "Internal armor is welded."
		),
		list(
			"key" = /obj/item/stack/sheet/plasteel,
			"amount" = 5,
			"back_key" = TOOL_CROWBAR,
			"desc" = "External armor is being installed."
		),
		list(
			"key" = TOOL_WRENCH,
			"back_key" = TOOL_CROWBAR,
			"desc" = "External armor is installed."
		),
		list(
			"key" = TOOL_WELDER,
			"back_key" = TOOL_WRENCH,
			"desc" = "External armor is wrenched."
		),
	)

/datum/component/construction/mecha/firefighter/custom_action(obj/item/I, mob/living/user, diff)
	if(!..())
		return FALSE

	//TODO: better messages.
	switch(index)
		if(1)
			user.visible_message(span_notice("[user] connects [parent] hydraulic systems."), span_notice("You connect [parent] hydraulic systems."))
		if(2)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] activates [parent] hydraulic systems."), span_notice("You activate [parent] hydraulic systems."))
			else
				user.visible_message(span_notice("[user] disconnects [parent] hydraulic systems."), span_notice("You disconnect [parent] hydraulic systems."))
		if(3)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] adds the wiring to [parent]."), span_notice("You add the wiring to [parent]."))
			else
				user.visible_message(span_notice("[user] deactivates [parent] hydraulic systems."), span_notice("You deactivate [parent] hydraulic systems."))
		if(4)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] adjusts the wiring of [parent]."), span_notice("You adjust the wiring of [parent]."))
			else
				user.visible_message(span_notice("[user] removes the wiring from [parent]."), span_notice("You remove the wiring from [parent]."))
		if(5)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] disconnects the wiring of [parent]."), span_notice("You disconnect the wiring of [parent]."))
		if(6)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the mainboard."), span_notice("You secure the mainboard."))
			else
				user.visible_message(span_notice("[user] removes the central control module from [parent]."), span_notice("You remove the central computer mainboard from [parent]."))
		if(7)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I]into [parent]."), span_notice("You install [I]into [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the mainboard."), span_notice("You unfasten the mainboard."))
		if(8)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the peripherals control module."), span_notice("You secure the peripherals control module."))
			else
				user.visible_message(span_notice("[user] removes the peripherals control module from [parent]."), span_notice("You remove the peripherals control module from [parent]."))
		if(9)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the peripherals control module."), span_notice("You unfasten the peripherals control module."))
		if(10)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the scanner module."), span_notice("You secure the scanner module."))
			else
				user.visible_message(span_notice("[user] removes the scanner module from [parent]."), span_notice("You remove the scanner module from [parent]."))
		if(11)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] to [parent]."), span_notice("You install [I] to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the scanner module."), span_notice("You unfasten the scanner module."))
		if(12)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the capacitor."), span_notice("You secure the capacitor."))
			else
				user.visible_message(span_notice("[user] removes the capacitor from [parent]."), span_notice("You remove the capacitor from [parent]."))
		if(13)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the capacitor."), span_notice("You unfasten the capacitor."))
		if(14)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the power cell."), span_notice("You secure the power cell."))
			else
				user.visible_message(span_notice("[user] pries the power cell from [parent]."), span_notice("You pry the power cell from [parent]."))
		if(15)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs the internal armor layer to [parent]."), span_notice("You install the internal armor layer to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the power cell."), span_notice("You unfasten the power cell."))
		if(16)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the internal armor layer."), span_notice("You secure the internal armor layer."))
			else
				user.visible_message(span_notice("[user] pries internal armor layer from [parent]."), span_notice("You pry internal armor layer from [parent]."))
		if(17)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] welds the internal armor layer to [parent]."), span_notice("You weld the internal armor layer to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the internal armor layer."), span_notice("You unfasten the internal armor layer."))
		if(18)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] starts to install the external armor layer to [parent]."), span_notice("You install the external armor layer to [parent]."))
			else
				user.visible_message(span_notice("[user] cuts the internal armor layer from [parent]."), span_notice("You cut the internal armor layer from [parent]."))
		if(19)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs the external reinforced armor layer to [parent]."), span_notice("You install the external reinforced armor layer to [parent]."))
			else
				user.visible_message(span_notice("[user] removes the external armor from [parent]."), span_notice("You remove the external armor from [parent]."))
		if(20)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the external armor layer."), span_notice("You secure the external reinforced armor layer."))
			else
				user.visible_message(span_notice("[user] pries external armor layer from [parent]."), span_notice("You pry external armor layer from [parent]."))
		if(21)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] welds the external armor layer to [parent]."), span_notice("You weld the external armor layer to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the external armor layer."), span_notice("You unfasten the external armor layer."))
	return TRUE

/datum/component/construction/unordered/mecha_chassis/durand
	result = /datum/component/construction/mecha/durand
	steps = list(
		/obj/item/mecha_parts/part/durand_torso,
		/obj/item/mecha_parts/part/durand_left_arm,
		/obj/item/mecha_parts/part/durand_right_arm,
		/obj/item/mecha_parts/part/durand_left_leg,
		/obj/item/mecha_parts/part/durand_right_leg,
		/obj/item/mecha_parts/part/durand_head
	)

/datum/component/construction/mecha/durand
	result = /obj/mecha/combat/durand
	base_icon = "durand"

	circuit_control = /obj/item/circuitboard/mecha/durand/main
	circuit_periph = /obj/item/circuitboard/mecha/durand/peripherals
	circuit_weapon = /obj/item/circuitboard/mecha/durand/targeting

	inner_plating = /obj/item/stack/sheet/metal
	inner_plating_amount = 5

	outer_plating = /obj/item/mecha_parts/part/durand_armor
	outer_plating_amount = 1

/datum/component/construction/mecha/durand/custom_action(obj/item/I, mob/living/user, diff)
	if(!..())
		return FALSE

	//TODO: better messages.
	switch(index)
		if(1)
			user.visible_message(span_notice("[user] connects [parent] hydraulic systems."), span_notice("You connect [parent] hydraulic systems."))
		if(2)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] activates [parent] hydraulic systems."), span_notice("You activate [parent] hydraulic systems."))
			else
				user.visible_message(span_notice("[user] disconnects [parent] hydraulic systems."), span_notice("You disconnect [parent] hydraulic systems."))
		if(3)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] adds the wiring to [parent]."), span_notice("You add the wiring to [parent]."))
			else
				user.visible_message(span_notice("[user] deactivates [parent] hydraulic systems."), span_notice("You deactivate [parent] hydraulic systems."))
		if(4)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] adjusts the wiring of [parent]."), span_notice("You adjust the wiring of [parent]."))
			else
				user.visible_message(span_notice("[user] removes the wiring from [parent]."), span_notice("You remove the wiring from [parent]."))
		if(5)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] disconnects the wiring of [parent]."), span_notice("You disconnect the wiring of [parent]."))
		if(6)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the mainboard."), span_notice("You secure the mainboard."))
			else
				user.visible_message(span_notice("[user] removes the central control module from [parent]."), span_notice("You remove the central computer mainboard from [parent]."))
		if(7)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the mainboard."), span_notice("You unfasten the mainboard."))
		if(8)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the peripherals control module."), span_notice("You secure the peripherals control module."))
			else
				user.visible_message(span_notice("[user] removes the peripherals control module from [parent]."), span_notice("You remove the peripherals control module from [parent]."))
		if(9)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the peripherals control module."), span_notice("You unfasten the peripherals control module."))
		if(10)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the weapon control module."), span_notice("You secure the weapon control module."))
			else
				user.visible_message(span_notice("[user] removes the weapon control module from [parent]."), span_notice("You remove the weapon control module from [parent]."))
		if(11)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] to [parent]."), span_notice("You install [I] to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the weapon control module."), span_notice("You unfasten the weapon control module."))
		if(12)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the scanner module."), span_notice("You secure the scanner module."))
			else
				user.visible_message(span_notice("[user] removes the scanner module from [parent]."), span_notice("You remove the scanner module from [parent]."))
		if(13)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] to [parent]."), span_notice("You install [I] to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the scanner module."), span_notice("You unfasten the scanner module."))
		if(14)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the capacitor."), span_notice("You secure the capacitor."))
			else
				user.visible_message(span_notice("[user] removes the capacitor from [parent]."), span_notice("You remove the capacitor from [parent]."))
		if(15)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the capacitor."), span_notice("You unfasten the capacitor."))
		if(16)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the power cell."), span_notice("You secure the power cell."))
			else
				user.visible_message(span_notice("[user] pries the power cell from [parent]."), span_notice("You pry the power cell from [parent]."))
		if(17)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs the internal armor layer to [parent]."), span_notice("You install the internal armor layer to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the power cell."), span_notice("You unfasten the power cell."))
		if(18)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the internal armor layer."), span_notice("You secure the internal armor layer."))
			else
				user.visible_message(span_notice("[user] pries internal armor layer from [parent]."), span_notice("You pry internal armor layer from [parent]."))
		if(19)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] welds the internal armor layer to [parent]."), span_notice("You weld the internal armor layer to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the internal armor layer."), span_notice("You unfasten the internal armor layer."))
		if(20)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] to [parent]."), span_notice("You install [I] to [parent]."))
			else
				user.visible_message(span_notice("[user] cuts the internal armor layer from [parent]."), span_notice("You cut the internal armor layer from [parent]."))
		if(21)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures Durand Armor Plates."), span_notice("You secure Durand Armor Plates."))
			else
				user.visible_message(span_notice("[user] pries Durand Armor Plates from [parent]."), span_notice("You pry Durand Armor Plates from [parent]."))
		if(22)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] welds Durand Armor Plates to [parent]."), span_notice("You weld Durand Armor Plates to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens Durand Armor Plates."), span_notice("You unfasten Durand Armor Plates."))
	return TRUE

//PHAZON

/datum/component/construction/unordered/mecha_chassis/phazon
	result = /datum/component/construction/mecha/phazon
	steps = list(
		/obj/item/mecha_parts/part/phazon_torso,
		/obj/item/mecha_parts/part/phazon_left_arm,
		/obj/item/mecha_parts/part/phazon_right_arm,
		/obj/item/mecha_parts/part/phazon_left_leg,
		/obj/item/mecha_parts/part/phazon_right_leg,
		/obj/item/mecha_parts/part/phazon_head
	)

/datum/component/construction/mecha/phazon
	result = /obj/mecha/combat/phazon
	base_icon = "phazon"

	circuit_control = /obj/item/circuitboard/mecha/phazon/main
	circuit_periph = /obj/item/circuitboard/mecha/phazon/peripherals
	circuit_weapon = /obj/item/circuitboard/mecha/phazon/targeting

	inner_plating = /obj/item/stack/sheet/plasteel
	inner_plating_amount = 5

	outer_plating = /obj/item/mecha_parts/part/phazon_armor
	outer_plating_amount = 1

/datum/component/construction/mecha/phazon/get_stockpart_steps()
	return list(
		list(
			"key" = /obj/item/stock_parts/scanning_module,
			"action" = ITEM_MOVE_INSIDE,
			"back_key" = TOOL_SCREWDRIVER,
			"desc" = "Weapon control module is secured."
		),
		list(
			"key" = TOOL_SCREWDRIVER,
			"back_key" = TOOL_CROWBAR,
			"desc" = "Scanner module is installed."
		),
		list(
			"key" = /obj/item/stock_parts/capacitor,
			"action" = ITEM_MOVE_INSIDE,
			"back_key" = TOOL_SCREWDRIVER,
			"desc" = "Scanner module is secured."
		),
		list(
			"key" = TOOL_SCREWDRIVER,
			"back_key" = TOOL_CROWBAR,
			"desc" = "Capacitor is installed."
		),
		list(
			"key" = /obj/item/stack/ore/bluespace_crystal,
			"amount" = 1,
			"back_key" = TOOL_SCREWDRIVER,
			"desc" = "Capacitor is secured."
		),
		list(
			"key" = /obj/item/stack/cable_coil,
			"amount" = 5,
			"back_key" = TOOL_CROWBAR,
			"desc" = "The bluespace crystal is installed."
		),
		list(
			"key" = TOOL_SCREWDRIVER,
			"back_key" = TOOL_WIRECUTTER,
			"desc" = "The bluespace crystal is connected."
		),
		list(
			"key" = /obj/item/stock_parts/cell,
			"action" = ITEM_MOVE_INSIDE,
			"back_key" = TOOL_SCREWDRIVER,
			"desc" = "The bluespace crystal is engaged."
		),
		list(
			"key" = TOOL_SCREWDRIVER,
			"back_key" = TOOL_CROWBAR,
			"desc" = "The power cell is installed.",
			"icon_state" = "phazon17"
			// This is the point where a step icon is skipped, so "icon_state" had to be set manually starting from here.
		)
	)

/datum/component/construction/mecha/phazon/get_outer_plating_steps()
	return list(
		list(
			"key" = outer_plating,
			"amount" = 1,
			"action" = ITEM_DELETE,
			"back_key" = TOOL_WELDER,
			"desc" = "Internal armor is welded."
		),
		list(
			"key" = TOOL_WRENCH,
			"back_key" = TOOL_CROWBAR,
			"desc" = "External armor is installed."
		),
		list(
			"key" = TOOL_WELDER,
			"back_key" = TOOL_WRENCH,
			"desc" = "External armor is wrenched."
		),
		list(
			"key" = /obj/item/assembly/signaler/anomaly, //WS Edit - Any anomaly core for Phazons
			"action" = ITEM_DELETE,
			"back_key" = TOOL_WELDER,
			"desc" = "Anomaly core socket is open.",
			"icon_state" = "phazon24"
		)
	)

/datum/component/construction/mecha/phazon/custom_action(obj/item/I, mob/living/user, diff)
	if(!..())
		return FALSE

	//TODO: better messages.
	switch(index)
		if(1)
			user.visible_message(span_notice("[user] connects [parent] hydraulic systems."), span_notice("You connect [parent] hydraulic systems."))
		if(2)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] activates [parent] hydraulic systems."), span_notice("You activate [parent] hydraulic systems."))
			else
				user.visible_message(span_notice("[user] disconnects [parent] hydraulic systems."), span_notice("You disconnect [parent] hydraulic systems."))
		if(3)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] adds the wiring to [parent]."), span_notice("You add the wiring to [parent]."))
			else
				user.visible_message(span_notice("[user] deactivates [parent] hydraulic systems."), span_notice("You deactivate [parent] hydraulic systems."))
		if(4)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] adjusts the wiring of [parent]."), span_notice("You adjust the wiring of [parent]."))
			else
				user.visible_message(span_notice("[user] removes the wiring from [parent]."), span_notice("You remove the wiring from [parent]."))
		if(5)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] disconnects the wiring of [parent]."), span_notice("You disconnect the wiring of [parent]."))
		if(6)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the mainboard."), span_notice("You secure the mainboard."))
			else
				user.visible_message(span_notice("[user] removes the central control module from [parent]."), span_notice("You remove the central computer mainboard from [parent]."))
		if(7)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the mainboard."), span_notice("You unfasten the mainboard."))
		if(8)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the peripherals control module."), span_notice("You secure the peripherals control module."))
			else
				user.visible_message(span_notice("[user] removes the peripherals control module from [parent]."), span_notice("You remove the peripherals control module from [parent]."))
		if(9)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the peripherals control module."), span_notice("You unfasten the peripherals control module."))
		if(10)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the weapon control module."), span_notice("You secure the weapon control module."))
			else
				user.visible_message(span_notice("[user] removes the weapon control module from [parent]."), span_notice("You remove the weapon control module from [parent]."))
		if(11)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] to [parent]."), span_notice("You install [I] to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the weapon control module."), span_notice("You unfasten the weapon control module."))
		if(12)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the scanner module."), span_notice("You secure the scanner module."))
			else
				user.visible_message(span_notice("[user] removes the scanner module from [parent]."), span_notice("You remove the scanner module from [parent]."))
		if(13)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] to [parent]."), span_notice("You install [I] to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the scanner module."), span_notice("You unfasten the scanner module."))
		if(14)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the capacitor."), span_notice("You secure the capacitor."))
			else
				user.visible_message(span_notice("[user] removes the capacitor from [parent]."), span_notice("You remove the capacitor from [parent]."))
		if(15)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I]."), span_notice("You install [I]."))
			else
				user.visible_message(span_notice("[user] unsecures the capacitor from [parent]."), span_notice("You unsecure the capacitor from [parent]."))
		if(16)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] connects the bluespace crystal."), span_notice("You connect the bluespace crystal."))
			else
				user.visible_message(span_notice("[user] removes the bluespace crystal from [parent]."), span_notice("You remove the bluespace crystal from [parent]."))
		if(17)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] engages the bluespace crystal."), span_notice("You engage the bluespace crystal."))
			else
				user.visible_message(span_notice("[user] disconnects the bluespace crystal from [parent]."), span_notice("You disconnect the bluespace crystal from [parent]."))
		if(18)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] disengages the bluespace crystal."), span_notice("You disengage the bluespace crystal."))
		if(19)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the power cell."), span_notice("You secure the power cell."))
			else
				user.visible_message(span_notice("[user] pries the power cell from [parent]."), span_notice("You pry the power cell from [parent]."))
		if(20)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs the phase armor layer to [parent]."), span_notice("You install the phase armor layer to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the power cell."), span_notice("You unfasten the power cell."))
		if(21)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the phase armor layer."), span_notice("You secure the phase armor layer."))
			else
				user.visible_message(span_notice("[user] pries the phase armor layer from [parent]."), span_notice("You pry the phase armor layer from [parent]."))
		if(22)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] welds the phase armor layer to [parent]."), span_notice("You weld the phase armor layer to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the phase armor layer."), span_notice("You unfasten the phase armor layer."))
		if(23)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] to [parent]."), span_notice("You install [I] to [parent]."))
			else
				user.visible_message(span_notice("[user] cuts phase armor layer from [parent]."), span_notice("You cut the phase armor layer from [parent]."))
		if(24)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures Phazon Armor Plates."), span_notice("You secure Phazon Armor Plates."))
			else
				user.visible_message(span_notice("[user] pries Phazon Armor Plates from [parent]."), span_notice("You pry Phazon Armor Plates from [parent]."))
		if(25)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] welds Phazon Armor Plates to [parent]."), span_notice("You weld Phazon Armor Plates to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens Phazon Armor Plates."), span_notice("You unfasten Phazon Armor Plates."))
		if(26)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] carefully inserts the anomaly core into [parent] and secures it."), //WS Edit
					span_notice("You slowly place the anomaly core into its socket and close its chamber.")) //WS Edit - Any anomaly core for phazons
	return TRUE

//ODYSSEUS

/datum/component/construction/unordered/mecha_chassis/odysseus
	result = /datum/component/construction/mecha/odysseus
	steps = list(
		/obj/item/mecha_parts/part/odysseus_torso,
		/obj/item/mecha_parts/part/odysseus_head,
		/obj/item/mecha_parts/part/odysseus_left_arm,
		/obj/item/mecha_parts/part/odysseus_right_arm,
		/obj/item/mecha_parts/part/odysseus_left_leg,
		/obj/item/mecha_parts/part/odysseus_right_leg
	)

/datum/component/construction/mecha/odysseus
	result = /obj/mecha/medical/odysseus
	base_icon = "odysseus"

	circuit_control = /obj/item/circuitboard/mecha/odysseus/main
	circuit_periph = /obj/item/circuitboard/mecha/odysseus/peripherals

	inner_plating = /obj/item/stack/sheet/metal
	inner_plating_amount = 5

	outer_plating = /obj/item/stack/sheet/plasteel
	outer_plating_amount = 5

/datum/component/construction/mecha/odysseus/custom_action(obj/item/I, mob/living/user, diff)
	if(!..())
		return FALSE

	//TODO: better messages.
	switch(index)
		if(1)
			user.visible_message(span_notice("[user] connects [parent] hydraulic systems."), span_notice("You connect [parent] hydraulic systems."))
		if(2)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] activates [parent] hydraulic systems."), span_notice("You activate [parent] hydraulic systems."))
			else
				user.visible_message(span_notice("[user] disconnects [parent] hydraulic systems."), span_notice("You disconnect [parent] hydraulic systems."))
		if(3)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] adds the wiring to [parent]."), span_notice("You add the wiring to [parent]."))
			else
				user.visible_message(span_notice("[user] deactivates [parent] hydraulic systems."), span_notice("You deactivate [parent] hydraulic systems."))
		if(4)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] adjusts the wiring of [parent]."), span_notice("You adjust the wiring of [parent]."))
			else
				user.visible_message(span_notice("[user] removes the wiring from [parent]."), span_notice("You remove the wiring from [parent]."))
		if(5)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] disconnects the wiring of [parent]."), span_notice("You disconnect the wiring of [parent]."))
		if(6)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the mainboard."), span_notice("You secure the mainboard."))
			else
				user.visible_message(span_notice("[user] removes the central control module from [parent]."), span_notice("You remove the central computer mainboard from [parent]."))
		if(7)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the mainboard."), span_notice("You unfasten the mainboard."))
		if(8)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the peripherals control module."), span_notice("You secure the peripherals control module."))
			else
				user.visible_message(span_notice("[user] removes the peripherals control module from [parent]."), span_notice("You remove the peripherals control module from [parent]."))
		if(9)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the peripherals control module."), span_notice("You unfasten the peripherals control module."))
		if(10)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the scanner module."), span_notice("You secure the scanner module."))
			else
				user.visible_message(span_notice("[user] removes the scanner module from [parent]."), span_notice("You remove the scanner module from [parent]."))
		if(11)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] to [parent]."), span_notice("You install [I] to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the scanner module."), span_notice("You unfasten the scanner module."))
		if(12)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the capacitor."), span_notice("You secure the capacitor."))
			else
				user.visible_message(span_notice("[user] removes the capacitor from [parent]."), span_notice("You remove the capacitor from [parent]."))
		if(13)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs [I] into [parent]."), span_notice("You install [I] into [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the capacitor."), span_notice("You unfasten the capacitor."))
		if(14)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the power cell."), span_notice("You secure the power cell."))
			else
				user.visible_message(span_notice("[user] pries the power cell from [parent]."), span_notice("You pry the power cell from [parent]."))
		if(15)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs the internal armor layer to [parent]."), span_notice("You install the internal armor layer to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the power cell."), span_notice("You unfasten the power cell."))
		if(16)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the internal armor layer."), span_notice("You secure the internal armor layer."))
			else
				user.visible_message(span_notice("[user] pries internal armor layer from [parent]."), span_notice("You pry internal armor layer from [parent]."))
		if(17)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] welds the internal armor layer to [parent]."), span_notice("You weld the internal armor layer to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the internal armor layer."), span_notice("You unfasten the internal armor layer."))
		if(18)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] installs the external armor layer to [parent]."), span_notice("You install the external reinforced armor layer to [parent]."))
			else
				user.visible_message(span_notice("[user] cuts the internal armor layer from [parent]."), span_notice("You cut the internal armor layer from [parent]."))
		if(19)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] secures the external armor layer."), span_notice("You secure the external reinforced armor layer."))
			else
				user.visible_message(span_notice("[user] pries the external armor layer from [parent]."), span_notice("You pry the external armor layer from [parent]."))
		if(20)
			if(diff==FORWARD)
				user.visible_message(span_notice("[user] welds the external armor layer to [parent]."), span_notice("You weld the external armor layer to [parent]."))
			else
				user.visible_message(span_notice("[user] unfastens the external armor layer."), span_notice("You unfasten the external armor layer."))
	return TRUE
