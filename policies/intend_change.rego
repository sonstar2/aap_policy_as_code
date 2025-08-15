package policies

# Define change window in UTC
intend_change_start_hour := 12 # 12:00 UTC (5 PM EST)

intend_change_end_hour := 4 # 04:00 UTC (9 AM EST)

# Extract the job creation timestamp (which is in UTC)
created_clock := time.clock(time.parse_rfc3339_ns(input.created)) # returns [hour, minute, second]

created_hour_utc := created_clock[0]

# Check if job was created within the maintenance window (UTC)
is_intend_change_time if {
	print("created_hour_utc: ", created_hour_utc)
	created_hour_utc >= intend_change_start_hour # After 12:00 UTC
}

is_intend_change_time if {
	print("created_hour_utc: ", created_hour_utc)
	created_hour_utc <= intend_change_end_hour # Before or at 04:00 UTC
}

default intend_change_window := {
	"allowed": true,
	"violations": [],
}

intend_change_window := {
	"allowed": false,
	"violations": ["No job execution allowed within intended change window"],
} if {
	is_intend_change_time
}
