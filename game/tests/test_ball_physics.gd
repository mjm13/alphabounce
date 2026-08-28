extends Node

var ball = null
var test_passed = 0
var test_failed = 0

func _ready():
	ball = $Ball
	_run_tests()

func _run_tests():
	# Test 1: Ball initial position
	if ball.position == Vector2(400, 300):
		test_passed += 1
		print("PASS: Ball initial position")
	else:
		test_failed += 1
		print("FAIL: Ball initial position, expected (400, 300), got ", ball.position)
	
	# Test 2: Ball velocity
	if ball.velocity == Vector2(0, 0):
		test_passed += 1
		print("PASS: Ball initial velocity")
	else:
		test_failed += 1
		print("FAIL: Ball initial velocity, expected (0, 0), got ", ball.velocity)
	
	# Print results
	print("")
	print("=" * 30)
	print("Test Results:")
	print("Passed: ", test_passed)
	print("Failed: ", test_failed)
	print("=" * 30)
	
	# Exit with appropriate code
	get_tree().quit(0 if test_failed == 0 else 1)
