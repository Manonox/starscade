extends Resource
class_name NetworkEmulationParameters


@export_range(0.0, 2000.0, 5.0) var ping := 0.0
@export_range(0.0, 50.0, 0.1) var ping_variance := 0.0
@export_range(0.0, 1.0, 0.01) var drop_chance := 0.0
@export_range(0.0, 1.0, 0.01) var duplicate_chance := 0.0


func get_fake_ping() -> float:
	return maxf(ping + randf() * 0.5 * ping_variance, 0.0)
