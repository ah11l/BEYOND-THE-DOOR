extends Node

## Google AdMob integration bridge (offline-first, non-blocking).
## - Small Top Banner Ad (auto-hides cleanly when offline)
## - Rewarded Ad for optional Hint & Skip Stage
## - Automatically uses official Google Test IDs in Debug builds to protect your AdMob account,
##   and uses your real production AdMob IDs in Release (Google Play AAB) builds.

signal banner_visibility_changed(is_visible: bool)
signal ad_reward_granted(placement: String)
signal ad_unavailable(placement: String, reason_key: String)

# Real Google AdMob IDs (used automatically in Release builds)
const APP_ID_ANDROID := "ca-app-pub-2956752840406313~2454089044"
const BANNER_UNIT_ID_PROD := "ca-app-pub-2956752840406313/8385284601"
const REWARDED_UNIT_ID_PROD := "ca-app-pub-2956752840406313/2152330002"

# Official Google AdMob Android Test IDs (used automatically in Debug builds)
const BANNER_UNIT_ID_TEST := "ca-app-pub-3940256099942544/6300978111"
const REWARDED_UNIT_ID_TEST := "ca-app-pub-3940256099942544/5224354917"

var ads_enabled: bool = true
var banner_visible: bool = false
var _plugin_ready: bool = false
var _ad_view: Variant = null
var _rewarded_ad: Variant = null
var _pending_placement: String = ""


func _ready() -> void:
	if OS.get_name() != "Android":
		return
	_try_initialize_mobile_ads()


func get_banner_unit_id() -> String:
	return BANNER_UNIT_ID_TEST if OS.is_debug_build() else BANNER_UNIT_ID_PROD


func get_rewarded_unit_id() -> String:
	return REWARDED_UNIT_ID_TEST if OS.is_debug_build() else REWARDED_UNIT_ID_PROD


func is_available() -> bool:
	return ads_enabled and _plugin_ready


func _try_initialize_mobile_ads() -> void:
	# Supports Poing Studios Godot AdMob Plugin when installed in addons/admob.
	# Fails safely and silently if offline or if native Android plugin is not bundled yet.
	if not Engine.has_singleton("PoingGodotAdMob"):
		_plugin_ready = false
		return
	_plugin_ready = true
	if ResourceLoader.exists("res://addons/admob/src/api/MobileAds.gd"):
		var mobile_ads_script := load("res://addons/admob/src/api/MobileAds.gd")
		if mobile_ads_script != null and mobile_ads_script.has_method("initialize"):
			mobile_ads_script.call("initialize")
			show_top_banner()
			preload_rewarded()


func show_top_banner() -> void:
	if not is_available():
		_set_banner_visible(false)
		return
	if not ResourceLoader.exists("res://addons/admob/src/api/AdView.gd"):
		_set_banner_visible(false)
		return
	var ad_view_cls := load("res://addons/admob/src/api/AdView.gd")
	var ad_size_cls := load("res://addons/admob/src/api/core/AdSize.gd")
	var ad_pos_cls := load("res://addons/admob/src/api/core/AdPosition.gd")
	var ad_req_cls := load("res://addons/admob/src/api/core/AdRequest.gd")
	if ad_view_cls == null or ad_size_cls == null or ad_pos_cls == null or ad_req_cls == null:
		_set_banner_visible(false)
		return
	if _ad_view != null:
		_ad_view.call("destroy")
		_ad_view = null
	var banner_size: Variant = ad_size_cls.get("BANNER")
	var top_pos: Variant = ad_pos_cls.get("Values").get("TOP")
	_ad_view = ad_view_cls.new(get_banner_unit_id(), banner_size, top_pos)
	_ad_view.call("load_ad", ad_req_cls.new())
	_set_banner_visible(true)


func hide_top_banner() -> void:
	if _ad_view != null:
		_ad_view.call("hide")
	_set_banner_visible(false)


func preload_rewarded() -> void:
	if not is_available():
		return
	if not ResourceLoader.exists("res://addons/admob/src/api/RewardedAdLoader.gd"):
		return
	var loader_cls := load("res://addons/admob/src/api/RewardedAdLoader.gd")
	var ad_req_cls := load("res://addons/admob/src/api/core/AdRequest.gd")
	var cb_cls := load("res://addons/admob/src/api/listeners/RewardedAdLoadCallback.gd")
	if loader_cls == null or ad_req_cls == null or cb_cls == null:
		return
	var callback: Variant = cb_cls.new()
	callback.on_ad_loaded = func(ad: Variant) -> void:
		_rewarded_ad = ad
	callback.on_ad_failed_to_load = func(_err: Variant) -> void:
		_rewarded_ad = null
	var loader: Variant = loader_cls.new()
	loader.call("load", get_rewarded_unit_id(), ad_req_cls.new(), callback)


func request_hint_ad() -> void:
	_request_rewarded("hint")


func request_skip_stage_ad() -> void:
	_request_rewarded("skip_stage")


func _request_rewarded(placement: String) -> void:
	if not is_available() or _rewarded_ad == null:
		ad_unavailable.emit(placement, "ad_offline_notice")
		preload_rewarded()
		return
	_pending_placement = placement
	var listener_cls := load("res://addons/admob/src/api/listeners/OnUserEarnedRewardListener.gd")
	if listener_cls == null:
		ad_unavailable.emit(placement, "ad_offline_notice")
		return
	var listener: Variant = listener_cls.new()
	listener.on_user_earned_reward = func(_reward_item: Variant) -> void:
		var granted_for := _pending_placement
		_pending_placement = ""
		_rewarded_ad = null
		ad_reward_granted.emit(granted_for)
		preload_rewarded()
	_rewarded_ad.call("show", listener)


func _set_banner_visible(vis: bool) -> void:
	if banner_visible != vis:
		banner_visible = vis
		banner_visibility_changed.emit(banner_visible)
