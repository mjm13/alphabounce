extends Node
class_name TestBase

# 自定义测试框架基类：提供断言与 AC 自检打印规范。
# 用法：派生本类，在 _ready() 中调用 assert_* / print_ac，headless 运行 test_suite.tscn 收集结果。

var _fail_count := 0

func _ready() -> void:
	print("TEST_BASE READY")

func assert_eq(a, b, msg := "") -> void:
	if a == b:
		print("ASSERT_EQ PASS: %s" % msg)
	else:
		_fail_count += 1
		printerr("ASSERT_EQ FAIL: %s (got %s, expected %s)" % [msg, str(a), str(b)])

func assert_true(c: bool, msg := "") -> void:
	if c:
		print("ASSERT_TRUE PASS: %s" % msg)
	else:
		_fail_count += 1
		printerr("ASSERT_TRUE FAIL: %s" % msg)

func assert_false(c: bool, msg := "") -> void:
	assert_true(not c, msg)

func print_ac(req_id: String, n: int, ok: bool) -> void:
	print("%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"])
	if not ok:
		_fail_count += 1

func has_failure() -> bool:
	return _fail_count > 0
