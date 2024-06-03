tool
extends VBoxContainer

var override_system_locale: String
var events_to_localize = ["text", "question", "choice"]
var timeline_folder: String = "res://dialogic/timelines/"
var csv_path: String = "res://dialogic/translation/dialogic_localization.csv"
var translations = {}


func _ready():
	var TranslationCheckbox = $TranslationIdBox/SettingsCheckbox/CheckBox
	TranslationCheckbox.connect('toggled', self, '_on_Translation_toggled')
	$GridContainer/CollectButton.connect("pressed", self, '_on_CollectButton_pressed')
	_on_Translation_toggled(TranslationCheckbox.pressed)


func _on_Translation_toggled(button_pressed):
	for n in $GridContainer.get_children():
		n.visible = button_pressed


func _on_CollectButton_pressed():
	print("Beginning localisation collection...")
	
	if $GridContainer/LineEdit.text != '':
		override_system_locale = $GridContainer/LineEdit.text
	if $GridContainer/LineEdit2.text == '':
		csv_path = "res://dialogic/translation/dialogic_localization.csv"
	else:
		csv_path = $GridContainer/LineEdit2.text
	
	check_and_create_directory_and_file()
	load_existing_translations()
	parse_dialogic_files()
	save_translations()
	
	print("Localisation collection complete...")


func check_and_create_directory_and_file():
	var dir = Directory.new()
	
	if not dir.dir_exists(csv_path.get_base_dir()):
		dir.make_dir_recursive(csv_path.get_base_dir())
		print("Created directory: ", csv_path.get_base_dir())
	
	if not dir.file_exists(csv_path):
		var file = File.new()
		file.open(csv_path, File.WRITE)
		file.store_line("")
		file.close()
		print("Created file: ", csv_path)


func load_existing_translations():
	var file = File.new()
	
	if file.open(csv_path, File.READ) == OK:
		while not file.eof_reached():
			var line = file.get_csv_line()
			if line.size() >= 2:
				translations[line[1]] = line[0]
		file.close()


func parse_dialogic_files():
	var dir = Directory.new()
	print("Collecting timeline data...")
	if dir.open(timeline_folder) == OK:
		dir.list_dir_begin()
		var filename = dir.get_next()
		
		while filename != "":
			if filename.ends_with(".json"):
				parse_json_file(timeline_folder + filename)
			filename = dir.get_next()


func parse_json_file(path: String):
	var file = File.new()
	if file.open(path, File.READ) == OK:
		var data = parse_json(file.get_as_text())
		file.close()
		var timeline_name = "unknown"
		
		if data.has("metadata") and data["metadata"].has("name"):
			timeline_name = data["metadata"]["name"]
		
		localize_text(data, timeline_name, 0, 0)
		
		if file.open(path, File.WRITE) == OK:
			file.store_string(to_json(data))
			file.close()


func localize_text(data, timeline_name, event_index, text_index):
	var next_text_index = text_index
	
	if typeof(data) == TYPE_DICTIONARY:
		for key in data.keys():
			if key in events_to_localize:
				var text = data[key]
				var loc_id = (timeline_name + "_" + str(key) + "_" + str(event_index) + "_" + str(next_text_index)).to_upper()
				data["localization_id"] = loc_id
				
				if not translations.has(text):
					translations[text] = loc_id
				
				next_text_index += 1
			elif typeof(data[key]) == TYPE_ARRAY or typeof(data[key]) == TYPE_DICTIONARY:
				next_text_index = localize_text(data[key], timeline_name, event_index, next_text_index)
			
	elif typeof(data) == TYPE_ARRAY:
		for item in data:
			next_text_index = localize_text(item, timeline_name, event_index, next_text_index)
			event_index += 1
	return next_text_index


func save_translations():
	var file = File.new()
	
	if file.open(csv_path, File.WRITE) == OK:
		var default_locale = OS.get_locale_language() if override_system_locale == "" else override_system_locale
		var header = ["id", default_locale.to_lower()]
		file.store_csv_line(header)
		
		for text in translations.keys():
			var row = [translations[text], text]
			file.store_csv_line(row)
		
		file.close()

