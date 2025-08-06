module mpv;
// See https://github.com/mpv-player/mpv/blob/master/include/mpv/client.h for documentation on each function
// https://mpv.io/manual/stable/#properties and https://mpv.io/manual/stable/#options lists runtime options that can be set by `set_prop` and `set_option` respectively
// https://mpv.io/manual/stable/#list-of-input-commands has a list of commands that can be sent by `command` and the other command functions
macro ZString[] to_zstr_slice(String[] strs) @private
{
	ZString[] zstrs = mem::temp_array(ZString, strs.len + 1);
	foreach (i, str : strs)
	{
		zstrs[i] = str.zstr_tcopy();
	}
	zstrs[^1] = null;
	return zstrs;
}

fn MpvVersion api_version() => (MpvVersion)mpv_client_api_version();

fn Mpv create() => mpv_create();

fn Mpv create_client(Mpv ctx, String client_name) => @pool()
{
	return mpv_create_client(ctx, client_name.zstr_tcopy());
}

fn Mpv create_weak_client(Mpv ctx, String client_name) => @pool()
{
	return mpv_create_weak_client(ctx, client_name.zstr_tcopy());
}

fn void? load_config_file(Mpv ctx, String file_name) => @pool()
{
	return wrap_err(mpv_load_config_file(ctx, file_name.zstr_tcopy()));
}

fn void free(void* data) => mpv_free(data);

fn void wakeup(Mpv ctx) => mpv_wakeup(ctx);

fn void set_wakeup_callback(Mpv ctx, MpvCallback callback, void* cb_data) => mpv_set_wakeup_callback(ctx, callback, cb_data);

fn void wait_async_requests(Mpv ctx) => mpv_wait_async_requests(ctx);

fn void? hook_add(Mpv ctx, MpvUserdata reply_userdata, String name, CInt priority) => @pool()
{
	return wrap_err(mpv_hook_add(ctx, reply_userdata, name.zstr_tcopy(), priority));
}

fn void? hook_continue(Mpv ctx, ulong id) => wrap_err(mpv_hook_continue(ctx, id));

/*fn void? observe_prop(Mpv ctx, String prop, MpvFormat format) => @pool()
{
	return wrap_err(mpv_observe_property(ctx, (MpvUserdata)prop.hash(), prop.zstr_tcopy(), format));
}

fn CInt? unobserve_prop(Mpv ctx, String prop)
{
	MpvError ret = mpv_unobserve_property(ctx, (MpvUserdata)prop.hash());
	return ret < 0 ? @catch(wrap_err(ret))? : (CInt)ret;
}

fn void? del_prop(Mpv ctx, String name) => @pool()
{
	return wrap_err(mpv_del_property(ctx, name.zstr_tcopy()));
}*/


// Sending commands to MPV
fn void? load_file(Mpv ctx, String file_name, bool replace) => command(ctx, "loadfile", file_name, replace ? "replace" : "append");

fn void? load_playlist(Mpv ctx, String file_name, bool replace) => command(ctx, "loadlist", file_name, replace ? "replace" : "append");

fn void? shuffle(Mpv ctx) => command(ctx, "playlist-shuffle");
fn void? unshuffle(Mpv ctx) => command(ctx, "playlist-unshuffle");

fn void? command(Mpv ctx, String... args) => @pool()
{
	return wrap_err(mpv_command(ctx, to_zstr_slice(args)));
}

fn MpvNode? command_node(Mpv ctx, MpvNode* args)
{
	MpvNode result;
	wrap_err(mpv_command_node(ctx, args, &result))!;
	return result;
}

fn MpvNode? command_ret(Mpv ctx, String... args) => @pool()
{
	MpvNode result;
	wrap_err(mpv_command_ret(ctx, to_zstr_slice(args), &result))!;
	return result;
}

fn void? command_string(Mpv ctx, String... args) => @pool()
{
	return wrap_err(mpv_command_string(ctx, to_zstr_slice(args)));
}

fn void? command_async(Mpv ctx, MpvUserdata reply_userdata, String... args) => @pool()
{
	return wrap_err(mpv_command_async(ctx, reply_userdata, to_zstr_slice(args)));
}

fn void? command_node_async(Mpv ctx, MpvUserdata reply_userdata, MpvNode* args) => @pool()
{
	return wrap_err(mpv_command_node_async(ctx, reply_userdata, args));
}

fn void abort_async_command(Mpv ctx, MpvUserdata reply_userdata) => mpv_abort_async_command(ctx, reply_userdata);

fn MpvEvent* wait_event(Mpv ctx, double timeout) => mpv_wait_event(ctx, timeout);

fn void? request_event(Mpv ctx, MpvEventId event, bool enable) => wrap_err(mpv_request_event(ctx, event, bool_to_mpv(enable)));

fn void? request_log_messages(Mpv ctx, MpvLogLevel min_level) => wrap_err(mpv_request_log_messages(ctx, min_level.to_zstr()));

// Mpv methods
fn void? Mpv.init(self) => wrap_err(mpv_initialize(self));

fn void Mpv.destroy(self) => mpv_destroy(self);

fn void Mpv.terminate_destroy(self) => mpv_terminate_destroy(self);

fn String Mpv.client_name(self) => mpv_client_name(self).str_view();

fn long Mpv.client_id(self) => mpv_client_id(self);

fn long Mpv.get_time_ns(self) => mpv_get_time_ns(self);

fn long Mpv.get_time_us(self) => mpv_get_time_us(self);

fn void? Mpv.set_song_idx(self, long idx) => self.set_prop_int("playlist-pos", idx);

fn void? Mpv.pause(self) => self.set_prop_flag("pause", true);

fn void? Mpv.unpause(self) => self.set_prop_flag("pause", false);

// Setting options
fn void? Mpv.set_option_string(self, String option, String value) => @pool()
{
	return self.set_option(option, STRING, &&value.zstr_tcopy());
}

fn void? Mpv.set_option_flag(self, String option, bool value) => self.set_option(option, FLAG, &&bool_to_mpv(value));

fn void? Mpv.set_option_int(self, String option, long value) => self.set_option(option, INT64, &value);

fn void? Mpv.set_option_double(self, String option, double value) => self.set_option(option, DOUBLE, &value);

fn void? Mpv.set_option_byte_array(self, String option, char[] value) => self.set_option(option, BYTE_ARRAY, &&(MpvByteArray){value.ptr, value.len});

fn void? Mpv.set_option(self, String option, MpvFormat format, void* value) => @pool()
{
	return wrap_err(mpv_set_option(self, option.zstr_tcopy(), format, value));
}

// TODO: would these be better as 'mpv::observe_prop(mpv, ...)'?
fn void? Mpv.observe_prop(self, String prop, MpvFormat format, MpvUserdata reply_userdata) => @pool()
{
	return wrap_err(mpv_observe_property(self, reply_userdata, prop.zstr_tcopy(), format));
}

fn CInt? Mpv.unobserve_prop(self, MpvUserdata registered_reply_userdata)
{
	MpvError ret = mpv_unobserve_property(self, registered_reply_userdata);
	return ret < 0 ? @catch(wrap_err(ret))? : (CInt)ret;
}

fn void? Mpv.del_prop(self, String name) => @pool()
{
	return wrap_err(mpv_del_property(self, name.zstr_tcopy()));
}


// Setting properties
fn void? Mpv.set_prop_string(self, String prop, String value) => @pool()
{
	return self.set_prop(prop, STRING, &&value.zstr_tcopy());
}

fn void? Mpv.set_prop_flag(self, String prop, bool value) => self.set_prop(prop, FLAG, &&bool_to_mpv(value));

fn void? Mpv.set_prop_int(self, String prop, long value) => self.set_prop(prop, INT64, &value);

fn void? Mpv.set_prop_double(self, String prop, double value) => self.set_prop(prop, DOUBLE, &value);

fn void? Mpv.set_prop_byte_array(self, String prop, char[] value) => self.set_prop(prop, BYTE_ARRAY, &&(MpvByteArray){value.ptr, value.len});

fn void? Mpv.set_prop(self, String prop, MpvFormat format, void* value) => @pool()
{
	return wrap_err(mpv_set_property(self, prop.zstr_tcopy(), format, value));
}


// Setting properties asynchronously
fn void? Mpv.set_prop_async_string(self, MpvUserdata reply_userdata, String prop, String value) => @pool()
{
	return self.set_prop_async(reply_userdata, prop, STRING, &&value.zstr_tcopy());
}

fn void? Mpv.set_prop_async_flag(self, MpvUserdata reply_userdata, String prop, bool value) => self.set_prop_async(reply_userdata, prop, FLAG, &&bool_to_mpv(value));

fn void? Mpv.set_prop_async_int(self, MpvUserdata reply_userdata, String prop, long value) => self.set_prop_async(reply_userdata, prop, INT64, &value);

fn void? Mpv.set_prop_async_double(self, MpvUserdata reply_userdata, String prop, double value) => self.set_prop_async(reply_userdata, prop, DOUBLE, &value);

fn void? Mpv.set_prop_async_byte_array(self, MpvUserdata reply_userdata, String prop, char[] value) => self.set_prop_async(reply_userdata, prop, BYTE_ARRAY, &&(MpvByteArray){value.ptr, value.len});

fn void? Mpv.set_prop_async(self, MpvUserdata reply_userdata, String prop, MpvFormat format, void* data) => @pool()
{
	return wrap_err(mpv_set_property_async(self, reply_userdata, prop.zstr_tcopy(), format, data));
}


// Reading properties
// These strings are allocated and need to be freed with mpv::free()
fn String? Mpv.get_prop_string(self, String prop)
{
	ZString z;
	self.get_prop(prop, STRING, &z)!;
	return z.str_view();
}

fn String? Mpv.get_prop_osd_string(self, String prop)
{
	ZString z;
	self.get_prop(prop, OSD_STRING, &z)!;
	return z.str_view();
}

fn bool? Mpv.get_prop_flag(self, String prop)
{
	MpvBool b;
	self.get_prop(prop, FLAG, &b)!;
	return b.as_bool;
}

fn long? Mpv.get_prop_int(self, String prop)
{
	long l;
	self.get_prop(prop, INT64, &l)!;
	return l;
}

fn double? Mpv.get_prop_double(self, String prop)
{
	double d;
	self.get_prop(prop, DOUBLE, &d)!;
	return d;
}

fn void? Mpv.get_prop(self, String prop, MpvFormat format, void* data) => @pool()
{
	return wrap_err(mpv_get_property(self, prop.zstr_tcopy(), format, data));
}


// Reading properties asynchronously
fn void? Mpv.get_prop_async(self, MpvUserdata reply_userdata, String prop, MpvFormat format) => @pool()
{
	return wrap_err(mpv_get_property_async(self, reply_userdata, prop.zstr_tcopy(), format));
}

// Other methods
fn String MpvEvent.name(&self) => mpv_event_name(self.event_id).str_view();

<* @require self.event_id == GET_PROPERTY_REPLY *>
fn MpvEventProperty* MpvEvent.get_property_reply(&self) => self.data;

<* @require self.event_id == PROPERTY_CHANGE *>
fn MpvEventProperty* MpvEvent.get_property_change(&self) => self.data;

<* @require self.event_id == LOG_MESSAGE *>
fn MpvEventLogMessage* MpvEvent.get_log_message(&self) => self.data;

<* @require self.event_id == START_FILE *>
fn MpvEventStartFile* MpvEvent.get_start_file(&self) => self.data;

<* @require self.event_id == END_FILE *>
fn MpvEventEndFile* MpvEvent.get_end_file(&self) => self.data;

<* @require self.event_id == HOOK *>
fn MpvEventHook* MpvEvent.get_hook(&self) => self.data;

<* @require self.event_id == COMMAND_REPLY *>
fn MpvEventCommand* MpvEvent.get_command_reply(&self) => self.data;

fn void MpvNode.free_contents(&self) => mpv_free_node_contents(self);

fn MpvNode? MpvEvent.to_node(&self)
{
	MpvNode n;
	wrap_err(mpv_event_to_node(&n, self))!;
	return n;
}

<*
 @require self.format == INT64
*>
fn long MpvEventProperty.get_int(&self) => *(long*)self.data;

<*
 @require self.format == FLAG
*>
fn bool MpvEventProperty.get_flag(&self) => ((MpvBool*)self.data).as_bool;

<*
 @require self.format == DOUBLE
*>
fn double MpvEventProperty.get_double(&self) => *(double*)self.data;

<*
 @require self.format == STRING
*>
fn String MpvEventProperty.get_string(&self) => ((ZString)self.data).str_view();

