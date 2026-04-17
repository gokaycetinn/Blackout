extends RefCounted

enum State {
	IDLE,
	PATROL,
	SUSPICIOUS,
	INVESTIGATING,
	CHASING,
	SEARCHING
}


static func state_to_string(state: int) -> String:
	match state:
		State.IDLE:
			return "IDLE"
		State.PATROL:
			return "PATROL"
		State.SUSPICIOUS:
			return "SUSPICIOUS"
		State.INVESTIGATING:
			return "INVESTIGATING"
		State.CHASING:
			return "CHASING"
		State.SEARCHING:
			return "SEARCHING"
		_:
			return "UNKNOWN"
