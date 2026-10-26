extends SceneTree

const ProgressManagerScript = preload("res://progress_manager.gd")
const SAVE_PATH := "user://historyroll_progress.json"
const CONFIRMATION_FLAG := "--confirm-reset-test-progress"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if not OS.has_feature("editor") and not OS.is_debug_build():
		_fail("Reset Test Progress is disabled outside editor/debug builds.")
		return
	if not OS.get_cmdline_user_args().has(CONFIRMATION_FLAG):
		_fail("Reset refused. Run with '-- %s' to confirm." % CONFIRMATION_FLAG)
		return

	var source_path := ProjectSettings.globalize_path(SAVE_PATH)
	if not FileAccess.file_exists(SAVE_PATH):
		_fail("Reset refused because the active save does not exist: %s" % source_path)
		return

	var original_hash := FileAccess.get_sha256(source_path)
	var timestamp := int(Time.get_unix_time_from_system())
	var backup_user_path := "user://historyroll_progress.backup-%d.json" % timestamp
	var backup_path := ProjectSettings.globalize_path(backup_user_path)
	var copy_error := DirAccess.copy_absolute(source_path, backup_path)
	if copy_error != OK:
		_fail("Could not back up the active save (error %d). No reset was performed." % copy_error)
		return
	if not FileAccess.file_exists(backup_user_path) or FileAccess.get_sha256(backup_path) != original_hash:
		_fail("Backup verification failed. No reset was performed.")
		return

	var fresh_progress = ProgressManagerScript.new()
	fresh_progress.save_path = SAVE_PATH
	if not fresh_progress.save_progress():
		DirAccess.copy_absolute(backup_path, source_path)
		fresh_progress.free()
		_fail("Could not write fresh progress. The original save was restored from backup.")
		return
	fresh_progress.free()

	var verification = ProgressManagerScript.new()
	verification.save_path = SAVE_PATH
	verification.load_progress()
	var valid_reset: bool = (
		verification.highest_unlocked_level == 1
		and verification.selected_level == 1
		and verification.completed_levels.is_empty()
		and verification.board_completed_levels.is_empty()
		and verification.completed_story_chapters.is_empty()
		and verification.claimed_character_rewards.is_empty()
		and verification.pending_progression_level == 0
		and verification.progression_stage.is_empty()
	)
	verification.free()
	if not valid_reset:
		DirAccess.copy_absolute(backup_path, source_path)
		_fail("Fresh-progress verification failed. The original save was restored from backup.")
		return

	print("Reset Test Progress completed.")
	print("BACKUP_PATH=", backup_path)
	print("BACKUP_SHA256=", original_hash)
	print("ACTIVE_SAVE_PATH=", source_path)
	print("ACTIVE_SAVE_SHA256=", FileAccess.get_sha256(source_path))
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
