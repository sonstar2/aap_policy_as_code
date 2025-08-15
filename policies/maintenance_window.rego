package policies

# Define plan change window in UTC
plan_change_start_hour := 12 # 12:00 UTC (5 PM EST)

plan_change_end_hour := 4 # 04:00 UTC (9 AM EST)

# Extract the job creation timestamp (which is in UTC)
created_clock := time.clock(time.parse_rfc3339_ns(input.created)) # returns [hour, minute, second]

created_hour_utc := created_clock[0]

# Check if job was created within the plan change window (UTC)
is_plan_change_time if {
	print("created_hour_utc: ", created_hour_utc)
	print("plan_change_start_hour: ", plan_change_start_hour)
	created_hour_utc >= plan_change_start_hour # After 12:00 UTC
}

is_plan_change_time if {
	print("created_hour_utc: ", created_hour_utc)
	print("plan_change_end_hour: ", plan_change_end_hour)
	created_hour_utc <= plan_change_end_hour # Before or at 04:00 UTC
}

default plan_change_window := {
	"allowed": true,
	"violations": [],
}

plan_change_window := {
	"allowed": false,
	"violations": ["No job execution allowed during plan change window"],
} if {
	is_plan_change_time
}
