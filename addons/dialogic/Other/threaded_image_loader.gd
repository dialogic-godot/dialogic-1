extends Reference


signal resource_loaded(res)

var thread: Thread = null

func _init():
	# Make sure the there is a reference to this object so we can keep the thread alive
	reference()
	thread = Thread.new()

func load_resource(path):
	var state = thread.start(self, "_thread_load", path)
	if state != OK:
		print("Error while starting thread: " + str(state))
		thread.wait_to_finish()
		unreference()

func _thread_load(path):
	var ril = ResourceLoader.load_interactive(path)
	var res = null

	while true:
		var err = ril.poll()
		if err == ERR_FILE_EOF:
			res = ril.get_resource()
			break
		elif err != OK:
			print("There was an error loading")
			break
	assert(res)
	emit_signal("resource_loaded", res)
	call_deferred("_thread_done")

func _thread_done():
	# Wait for the thread to finish before removing it
	thread.wait_to_finish()
	unreference()
