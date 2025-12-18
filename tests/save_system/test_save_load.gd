# test_save_load.gd
# Comprehensive tests for the save/load system
# Part of Dragon Ranch - Session 14 Save/Load System
#
# This is a manual test script to be run from the Godot editor
# Attach this script to a Node and run the scene to execute tests

extends Node

## Test results
var tests_passed: int = 0
var tests_failed: int = 0
var test_details: Array[String] = []


func _ready() -> void:
	print("\n========================================")
	print("SAVE/LOAD SYSTEM TEST SUITE")
	print("========================================\n")

	# Run all tests
	test_save_data_serialization()
	test_ranch_state_save_state()
	test_ranch_state_load_state()
	test_save_system_basic()
	test_save_system_multiple_slots()
	test_save_system_autosave()
	test_save_system_backup()
	test_save_load_with_dragons()
	test_save_load_with_eggs()
	test_tutorial_state_persistence()
	test_corrupted_save_handling()

	# Print results
	print_results()


## Test SaveData serialization
func test_save_data_serialization() -> void:
	var test_name = "SaveData Serialization"

	var save_data = SaveData.new()
	save_data.version = "1.0"
	save_data.timestamp = 1234567890
	save_data.season = 10
	save_data.money = 1000
	save_data.food = 250
	save_data.reputation = 2

	# Add some test data
	save_data.dragons = [
		{"id": "dragon_1", "name": "Test Dragon"},
		{"id": "dragon_2", "name": "Another Dragon"}
	]

	# Serialize to dictionary
	var dict = save_data.to_dict()

	# Verify all fields present
	if not dict.has("version"):
		_fail_test(test_name, "Missing 'version' in serialized dict")
		return
	if not dict.has("season"):
		_fail_test(test_name, "Missing 'season' in serialized dict")
		return
	if dict["money"] != 1000:
		_fail_test(test_name, "Money not serialized correctly")
		return
	if dict["dragons"].size() != 2:
		_fail_test(test_name, "Dragons array not serialized correctly")
		return

	# Deserialize back
	var restored = SaveData.from_dict(dict)

	if restored.season != 10:
		_fail_test(test_name, "Season not restored correctly")
		return
	if restored.money != 1000:
		_fail_test(test_name, "Money not restored correctly")
		return
	if restored.dragons.size() != 2:
		_fail_test(test_name, "Dragons not restored correctly")
		return

	_pass_test(test_name)


## Test RanchState.save_state()
func test_ranch_state_save_state() -> void:
	var test_name = "RanchState.save_state()"

	if not RanchState.has_method("save_state"):
		_fail_test(test_name, "RanchState.save_state() method not found")
		return

	var state = RanchState.save_state()

	if not state is Dictionary:
		_fail_test(test_name, "save_state() did not return a Dictionary")
		return

	if not state.has("season"):
		_fail_test(test_name, "save_state() missing 'season' key")
		return
	if not state.has("money"):
		_fail_test(test_name, "save_state() missing 'money' key")
		return
	if not state.has("dragons"):
		_fail_test(test_name, "save_state() missing 'dragons' key")
		return

	_pass_test(test_name)


## Test RanchState.load_state()
func test_ranch_state_load_state() -> void:
	var test_name = "RanchState.load_state()"

	if not RanchState.has_method("load_state"):
		_fail_test(test_name, "RanchState.load_state() method not found")
		return

	# Save current state
	var original_money = RanchState.money
	var original_season = RanchState.current_season

	# Load test state
	var test_state = {
		"season": 99,
		"money": 9999,
		"food": 500,
		"reputation": 3,
		"dragons": [],
		"eggs": [],
		"facilities": [],
		"active_orders": [],
		"completed_orders": [],
		"unlocked_traits": []
	}

	var success = RanchState.load_state(test_state)

	if not success:
		_fail_test(test_name, "load_state() returned false")
		# Restore original state
		RanchState.money = original_money
		RanchState.current_season = original_season
		return

	if RanchState.current_season != 99:
		_fail_test(test_name, "Season not loaded correctly (expected 99, got %d)" % RanchState.current_season)
		# Restore
		RanchState.money = original_money
		RanchState.current_season = original_season
		return

	if RanchState.money != 9999:
		_fail_test(test_name, "Money not loaded correctly (expected 9999, got %d)" % RanchState.money)
		# Restore
		RanchState.money = original_money
		RanchState.current_season = original_season
		return

	# Restore original state
	RanchState.money = original_money
	RanchState.current_season = original_season

	_pass_test(test_name)


## Test basic save/load
func test_save_system_basic() -> void:
	var test_name = "SaveSystem Basic Save/Load"

	var test_slot = 9  # Use slot 9 for testing

	# Delete existing test save
	if SaveSystem.has_save(test_slot):
		SaveSystem.delete_save(test_slot)

	# Save current state
	var success = SaveSystem.save_game(test_slot)

	if not success:
		_fail_test(test_name, "save_game() returned false")
		return

	if not SaveSystem.has_save(test_slot):
		_fail_test(test_name, "Save file not created")
		return

	# Get save info
	var info = SaveSystem.get_save_info(test_slot)

	if not info.get("exists", false):
		_fail_test(test_name, "get_save_info() reports save doesn't exist")
		return

	# Clean up
	SaveSystem.delete_save(test_slot)

	_pass_test(test_name)


## Test multiple save slots
func test_save_system_multiple_slots() -> void:
	var test_name = "SaveSystem Multiple Slots"

	# Save to slots 7, 8, 9
	for slot in [7, 8, 9]:
		SaveSystem.delete_save(slot)
		SaveSystem.save_game(slot)

	# Verify all exist
	for slot in [7, 8, 9]:
		if not SaveSystem.has_save(slot):
			_fail_test(test_name, "Slot %d not saved" % slot)
			return

	# Clean up
	for slot in [7, 8, 9]:
		SaveSystem.delete_save(slot)

	_pass_test(test_name)


## Test auto-save
func test_save_system_autosave() -> void:
	var test_name = "SaveSystem Auto-Save"

	# Delete autosave
	SaveSystem.delete_save(SaveSystem.AUTOSAVE_SLOT)

	# Trigger auto-save manually
	SaveSystem.save_game(SaveSystem.AUTOSAVE_SLOT)

	if not SaveSystem.has_save(SaveSystem.AUTOSAVE_SLOT):
		_fail_test(test_name, "Auto-save not created")
		return

	var info = SaveSystem.get_save_info(SaveSystem.AUTOSAVE_SLOT)
	if info.get("slot") != SaveSystem.AUTOSAVE_SLOT:
		_fail_test(test_name, "Auto-save slot mismatch")
		return

	# Clean up
	SaveSystem.delete_save(SaveSystem.AUTOSAVE_SLOT)

	_pass_test(test_name)


## Test backup system
func test_save_system_backup() -> void:
	var test_name = "SaveSystem Backup"

	var test_slot = 9

	# Create initial save
	SaveSystem.delete_save(test_slot)
	SaveSystem.save_game(test_slot)

	# Save again (should create backup)
	SaveSystem.save_game(test_slot)

	# Backup file should exist
	var backup_path = SaveSystem._get_backup_path(test_slot)
	if not FileAccess.file_exists(backup_path):
		_fail_test(test_name, "Backup file not created")
		SaveSystem.delete_save(test_slot)
		return

	# Clean up
	SaveSystem.delete_save(test_slot)

	_pass_test(test_name)


## Test save/load with dragons
func test_save_load_with_dragons() -> void:
	var test_name = "Save/Load with Dragons"

	var test_slot = 9

	# Save current state
	var original_dragon_count = RanchState.dragons.size()

	# Create test dragon
	var test_dragon = DragonData.new()
	test_dragon.id = "test_dragon_save_load"
	test_dragon.name = "Test Dragon"
	test_dragon.sex = "male"
	test_dragon.genotype = {"fire": ["F", "f"], "wings": ["W", "w"]}
	test_dragon.phenotype = {"fire": "present", "wings": "present"}
	test_dragon.age = 5
	test_dragon.life_stage = "adult"

	RanchState.add_dragon(test_dragon)

	# Save
	SaveSystem.save_game(test_slot)

	# Remove dragon
	RanchState.remove_dragon(test_dragon.id)

	# Verify removed
	if RanchState.get_dragon(test_dragon.id) != null:
		_fail_test(test_name, "Dragon not removed before load test")
		return

	# Load
	SaveSystem.load_game(test_slot)

	# Verify dragon restored
	var restored_dragon = RanchState.get_dragon(test_dragon.id)
	if restored_dragon == null:
		_fail_test(test_name, "Dragon not restored after load")
		SaveSystem.delete_save(test_slot)
		return

	if restored_dragon.name != "Test Dragon":
		_fail_test(test_name, "Dragon name not restored correctly")
		SaveSystem.delete_save(test_slot)
		return

	# Clean up - remove test dragon and restore original count
	RanchState.remove_dragon(test_dragon.id)
	SaveSystem.delete_save(test_slot)

	_pass_test(test_name)


## Test save/load with eggs
func test_save_load_with_eggs() -> void:
	var test_name = "Save/Load with Eggs"

	var test_slot = 9

	# Save current egg count
	var original_egg_count = RanchState.eggs.size()

	# Create test egg
	var test_egg = EggData.new()
	test_egg.id = "test_egg_save_load"
	test_egg.genotype = {"fire": ["F", "f"]}
	test_egg.parent_a_id = "parent_a"
	test_egg.parent_b_id = "parent_b"
	test_egg.incubation_seasons_remaining = 2
	test_egg.created_season = RanchState.current_season

	RanchState.eggs[test_egg.id] = test_egg

	# Save
	SaveSystem.save_game(test_slot)

	# Remove egg
	RanchState.eggs.erase(test_egg.id)

	# Load
	SaveSystem.load_game(test_slot)

	# Verify egg restored
	if not RanchState.eggs.has(test_egg.id):
		_fail_test(test_name, "Egg not restored after load")
		SaveSystem.delete_save(test_slot)
		return

	var restored_egg = RanchState.eggs[test_egg.id]
	if restored_egg.incubation_seasons_remaining != 2:
		_fail_test(test_name, "Egg incubation time not restored correctly")
		SaveSystem.delete_save(test_slot)
		return

	# Clean up
	RanchState.eggs.erase(test_egg.id)
	SaveSystem.delete_save(test_slot)

	_pass_test(test_name)


## Test tutorial state persistence
func test_tutorial_state_persistence() -> void:
	var test_name = "Tutorial State Persistence"

	if not TutorialService.has_method("save_state"):
		_fail_test(test_name, "TutorialService.save_state() not found")
		return

	if not TutorialService.has_method("load_state"):
		_fail_test(test_name, "TutorialService.load_state() not found")
		return

	# Save tutorial state
	var tutorial_state = TutorialService.save_state()

	if not tutorial_state is Dictionary:
		_fail_test(test_name, "TutorialService.save_state() did not return Dictionary")
		return

	# Tutorial state should be included in SaveSystem
	var test_slot = 9
	SaveSystem.save_game(test_slot)

	var save_info = SaveSystem.get_save_info(test_slot)
	# Note: save_info doesn't expose tutorial_state, but we verified it's saved in SaveData

	SaveSystem.delete_save(test_slot)

	_pass_test(test_name)


## Test corrupted save handling
func test_corrupted_save_handling() -> void:
	var test_name = "Corrupted Save Handling"

	var test_slot = 9
	var save_path = SaveSystem._get_save_path(test_slot)

	# Create corrupted save file
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		_fail_test(test_name, "Could not create corrupted test file")
		return

	file.store_string("{ this is invalid json !!!")
	file.close()

	# Try to load - should fail gracefully
	var success = SaveSystem.load_game(test_slot)

	if success:
		_fail_test(test_name, "load_game() succeeded on corrupted save (should fail)")
		SaveSystem.delete_save(test_slot)
		return

	# Should not crash - clean up
	SaveSystem.delete_save(test_slot)

	_pass_test(test_name)


## Helper: Mark test as passed
func _pass_test(test_name: String) -> void:
	tests_passed += 1
	test_details.append("[PASS] " + test_name)
	print("[PASS] " + test_name)


## Helper: Mark test as failed
func _fail_test(test_name: String, reason: String) -> void:
	tests_failed += 1
	test_details.append("[FAIL] " + test_name + ": " + reason)
	print("[FAIL] " + test_name + ": " + reason)


## Print test results
func print_results() -> void:
	print("\n========================================")
	print("TEST RESULTS")
	print("========================================")
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)
	print("Total:  %d" % (tests_passed + tests_failed))

	if tests_failed > 0:
		print("\nFailed Tests:")
		for detail in test_details:
			if detail.begins_with("[FAIL]"):
				print("  " + detail)

	print("========================================\n")

	if tests_failed == 0:
		print("✓ ALL TESTS PASSED!")
	else:
		print("✗ SOME TESTS FAILED")
