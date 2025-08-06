module mpv;
import std::io;

faultdef EVENT_QUEUE_FULL, NOMEM, UNINITIALIZED, INVALID_PARAMETER,
		OPTION_NOT_FOUND, OPTION_FORMAT, OPTION_ERROR,
		PROPERTY_NOT_FOUND, PROPERTY_FORMAT, PROPERTY_UNAVAILABLE,
		PROPERTY_ERROR, COMMAND, LOADING_FAILED, AO_INIT_FAILED,
		VO_INIT_FAILED, NOTHING_TO_PLAY, UNKNOWN_FORMAT, UNSUPPORTED,
		NOT_IMPLEMENTED, GENERIC;

typedef Mpv = void*;
typedef MpvUserdata = ulong;

bitstruct MpvVersion (Printable) : CULong
{
	uint minor : 0..15;
	uint major : 16..31;
}

fn usz? MpvVersion.to_format(&self, Formatter* fmt) @dynamic
{
	return fmt.printf("%s.%s", self.major, self.minor);
}

struct MpvNode
{
	union u
	{
		ZString string;
		MpvBool flag;
		long int64;
		double double_;
		MpvNodeList* list;
		MpvByteArray* ba;
	}
	MpvFormat format;
}

struct MpvNodeList
{
	CInt num;
	MpvNode *values;
	ZString* keys;
}

struct MpvByteArray
{
	void *data;
	usz size;
}

struct MpvEventProperty
{
	ZString name;
	MpvFormat format;
	void *data;
}

struct MpvEventLogMessage
{
	ZString prefix;
	ZString level;
	ZString text;
	MpvLogLevel log_level;
}

struct MpvEventStartFile
{
	isz playlist_entry_id;
}

struct MpvEventEndFile
{
	MpvEndFileReason reason;
	MpvError error;
	isz playlist_entry_id;
	isz playlist_insert_id;
	CInt playlist_insert_num_entries;
}

struct MpvEventClientMessage
{
	CInt num_args;
	ZString* args;
}

struct MpvEventHook
{
	ZString name;
	usz id;
}

struct MpvEventCommand
{
	MpvNode result;
}

struct MpvEvent
{
	MpvEventId event_id;
	MpvError error;
	MpvUserdata reply_userdata;
	/*
	 * The meaning and contents of the data member depend on the event_id:
	 *  MPV_EVENT_GET_PROPERTY_REPLY:     MpvEventProperty*
	 *  MPV_EVENT_PROPERTY_CHANGE:        MpvEventProperty*
	 *  MPV_EVENT_LOG_MESSAGE:            MpvEventLogMessage*
	 *  MPV_EVENT_CLIENT_MESSAGE:         MpvEventClientMessage*
	 *  MPV_EVENT_START_FILE:             MpvEventStartFile* (since v1.108)
	 *  MPV_EVENT_END_FILE:               MpvEventEndFile*
	 *  MPV_EVENT_HOOK:                   MpvEventHook*
	 *  MPV_EVENT_COMMAND_REPLY*          MpvEventCommand*
	 *  other: NULL
	 *
	 * Note: future enhancements might add new event structs for existing or new
	 *       event types.
	 */
	void *data;
}

alias MpvCallback = fn void(void*);

enum MpvBool : CInt (bool as_bool)
{
	FALSE = false,
	TRUE = true,
}

macro MpvBool bool_to_mpv(bool b) => b ? TRUE : FALSE;

enum MpvFormat : CInt
{
	NONE,
	STRING,
	OSD_STRING,
	FLAG,
	INT64,
	DOUBLE,
	NODE,
	NODE_ARRAY,
	NODE_MAP,
	BYTE_ARRAY,
}

enum MpvEndFileReason (Printable) : const CInt
{
	EOF = 0,
	STOP = 2,
	QUIT = 3,
	ERROR = 4,
	REDIRECT = 5,
}

fn String MpvEndFileReason.to_constant_string(&self, Formatter* fmt) @dynamic
{
	switch (*self)
	{
		case EOF: return "EOF";
		case STOP: return "STOP";
		case QUIT: return "QUIT";
		case ERROR: return "ERROR";
		case REDIRECT: return "REDIRECT";
		default: return "UNKNOWN";
	}
}

macro void? wrap_err(MpvError val) @private
{
	switch (val)
	{
		case SUCCESS: return;
		case EVENT_QUEUE_FULL: return EVENT_QUEUE_FULL?;
		case NOMEM: return NOMEM?;
		case UNINITIALIZED: return UNINITIALIZED?;
		case INVALID_PARAMETER: return INVALID_PARAMETER?;
		case OPTION_NOT_FOUND: return OPTION_NOT_FOUND?;
		case OPTION_FORMAT: return OPTION_FORMAT?;
		case OPTION_ERROR: return OPTION_ERROR?;
		case PROPERTY_NOT_FOUND: return PROPERTY_NOT_FOUND?;
		case PROPERTY_FORMAT: return PROPERTY_FORMAT?;
		case PROPERTY_UNAVAILABLE: return PROPERTY_UNAVAILABLE?;
		case PROPERTY_ERROR: return PROPERTY_ERROR?;
		case COMMAND: return COMMAND?;
		case LOADING_FAILED: return LOADING_FAILED?;
		case AO_INIT_FAILED: return AO_INIT_FAILED?;
		case VO_INIT_FAILED: return VO_INIT_FAILED?;
		case NOTHING_TO_PLAY: return NOTHING_TO_PLAY?;
		case UNKNOWN_FORMAT: return UNKNOWN_FORMAT?;
		case UNSUPPORTED: return UNSUPPORTED?;
		case NOT_IMPLEMENTED: return NOT_IMPLEMENTED?;
		case GENERIC: return GENERIC?;
		default:// return (CInt)val;
			unreachable("Invalid MPV error code");
	}
}

fn String error_string(fault err) @inline
{
	MpvError err_val;
	switch (err)
	{
		case EVENT_QUEUE_FULL: err_val = EVENT_QUEUE_FULL;
		case NOMEM: err_val = NOMEM;
		case UNINITIALIZED: err_val = UNINITIALIZED;
		case INVALID_PARAMETER: err_val = INVALID_PARAMETER;
		case OPTION_NOT_FOUND: err_val = OPTION_NOT_FOUND;
		case OPTION_FORMAT: err_val = OPTION_FORMAT;
		case OPTION_ERROR: err_val = OPTION_ERROR;
		case PROPERTY_NOT_FOUND: err_val = PROPERTY_NOT_FOUND;
		case PROPERTY_FORMAT: err_val = PROPERTY_FORMAT;
		case PROPERTY_UNAVAILABLE: err_val = PROPERTY_UNAVAILABLE;
		case PROPERTY_ERROR: err_val = PROPERTY_ERROR;
		case COMMAND: err_val = COMMAND;
		case LOADING_FAILED: err_val = LOADING_FAILED;
		case AO_INIT_FAILED: err_val = AO_INIT_FAILED;
		case VO_INIT_FAILED: err_val = VO_INIT_FAILED;
		case NOTHING_TO_PLAY: err_val = NOTHING_TO_PLAY;
		case UNKNOWN_FORMAT: err_val = UNKNOWN_FORMAT;
		case UNSUPPORTED: err_val = UNSUPPORTED;
		case NOT_IMPLEMENTED: err_val = NOT_IMPLEMENTED;
		case GENERIC: err_val = GENERIC;
		default:
			unreachable("Not an MPV error: %s", err);
	}
	return mpv_error_string(err_val).str_view();
}

enum MpvEventId : const CInt
{
	NONE = 0,
	SHUTDOWN,
	LOG_MESSAGE,
	GET_PROPERTY_REPLY,
	SET_PROPERTY_REPLY,
	COMMAND_REPLY,
	START_FILE,
	END_FILE,
	FILE_LOADED,
	CLIENT_MESSAGE = 16,
	VIDEO_RECONFIG,
	AUDIO_RECONFIG,
	SEEK = 20,
	PLAYBACK_RESTART,
	PROPERTY_CHANGE,
	QUEUE_OVERFLOW = 24,
	HOOK
}

enum MpvLogLevel : const CInt
{
	NONE  = 0,
	FATAL = 10,
	ERROR = 20,
	WARN  = 30,
	INFO  = 40,
	V     = 50,
	DEBUG = 60,
	TRACE = 70,
}

fn ZString MpvLogLevel.to_zstr(self)
{
	switch (self)
	{
		case NONE: return "no";
		case FATAL: return "fatal";
		case ERROR: return "error";
		case WARN: return "warn";
		case INFO: return "info";
		case V: return "v";
		case DEBUG: return "debug";
		case TRACE: return "trace";
		default: unreachable("invalid MpvLogLevel: %s", self);
	}
}

enum MpvError (Printable) : const CInt
{
	SUCCESS           = 0,
	EVENT_QUEUE_FULL  = -1,
	NOMEM             = -2,
	UNINITIALIZED     = -3,
	INVALID_PARAMETER = -4,
	OPTION_NOT_FOUND  = -5,
	OPTION_FORMAT     = -6,
	OPTION_ERROR      = -7,
	PROPERTY_NOT_FOUND = -8,
	PROPERTY_FORMAT   = -9,
	PROPERTY_UNAVAILABLE = -10,
	PROPERTY_ERROR    = -11,
	COMMAND           = -12,
	LOADING_FAILED    = -13,
	AO_INIT_FAILED    = -14,
	VO_INIT_FAILED    = -15,
	NOTHING_TO_PLAY   = -16,
	UNKNOWN_FORMAT    = -17,
	UNSUPPORTED       = -18,
	NOT_IMPLEMENTED   = -19,
	GENERIC           = -20
}

fn String MpvError.to_constant_string(&self) @dynamic => mpv_error_string(*self).str_view();
