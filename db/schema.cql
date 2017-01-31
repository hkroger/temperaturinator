CREATE TABLE temperatures.measurements_monthly_avg (
    location_id int,
    year_month text,
    temperature_count counter,
    temperature_sum_in_cents counter,
    PRIMARY KEY (location_id, year_month)
) WITH CLUSTERING ORDER BY (year_month ASC);

CREATE TABLE temperatures.alarm_logs_by_client (
    client_id timeuuid,
    id timeuuid,
    alarm_id timeuuid,
    location_id int,
    measurement double,
    message text,
    PRIMARY KEY (client_id, id)
) WITH CLUSTERING ORDER BY (id DESC);

CREATE TABLE temperatures.clients (
    id timeuuid PRIMARY KEY,
    disabled_at timestamp,
    name text,
    signing_key uuid,
    user text
);

CREATE TABLE temperatures.process_statuses (
    process_name text PRIMARY KEY,
    last_updated_at timestamp
);

CREATE TABLE temperatures.measurements (
    location_id int,
    year_month text,
    id timeuuid,
    measurement double,
    signal_strength decimal,
    voltage decimal,
    PRIMARY KEY ((location_id, year_month), id)
) WITH CLUSTERING ORDER BY (id ASC);

CREATE TABLE temperatures.alarm_logs_by_location (
    location_id int,
    id timeuuid,
    alarm_id timeuuid,
    client_id timeuuid,
    measurement double,
    message text,
    PRIMARY KEY (location_id, id)
) WITH CLUSTERING ORDER BY (id DESC);

CREATE TABLE temperatures.measurements_monthly_min_max (
    location_id int,
    year_month text,
    max double,
    max_at timestamp,
    min double,
    min_at timestamp,
    PRIMARY KEY (location_id, year_month)
);

CREATE TABLE temperatures.locations (
    id int PRIMARY KEY,
    client_id timeuuid,
    description text,
    do_not_alarm boolean,
    do_not_show boolean,
    sensors set<int>,
    username text
);

CREATE TABLE temperatures.alarm_notifications_by_alarm (
    alarm_id timeuuid,
    username text,
    created_at timestamp,
    email boolean,
    pushover boolean,
    updated_at timestamp,
    PRIMARY KEY (alarm_id, username)
) WITH CLUSTERING ORDER BY (username ASC);

CREATE TABLE temperatures.measurements_daily_min_max (
    location_id int,
    day timestamp,
    max double,
    max_at timestamp,
    min double,
    min_at timestamp,
    PRIMARY KEY (location_id, day)
) WITH CLUSTERING ORDER BY (day ASC);

CREATE TABLE temperatures.measurements_daily_avg (
    location_id int,
    year_month text,
    day timestamp,
    temperature_count counter,
    temperature_sum_in_cents counter,
    PRIMARY KEY ((location_id, year_month), day)
) WITH CLUSTERING ORDER BY (day ASC);

CREATE TABLE temperatures.measurements_hourly_avg (
    location_id int,
    year_month text,
    hour timestamp,
    temperature_count counter,
    temperature_sum_in_cents counter,
    PRIMARY KEY ((location_id, year_month), hour)
) WITH CLUSTERING ORDER BY (hour ASC);

CREATE TABLE temperatures.measurements_stats (
    location_id int PRIMARY KEY,
    alarmed_at timestamp,
    current double,
    first_read_at timestamp,
    last_read_at timestamp,
    max double,
    max_at timestamp,
    min double,
    min_at timestamp
);

CREATE TABLE temperatures.alarms (
    location_id int,
    id timeuuid,
    alarm_when_warmer boolean,
    alarmed boolean,
    created_at timestamp,
    delay int,
    hysteresis float,
    owner text,
    temperature float,
    two_way_alarm boolean,
    updated_at timestamp,
    PRIMARY KEY (location_id, id)
) WITH CLUSTERING ORDER BY (id ASC);

CREATE TABLE temperatures.sensors (
    id int PRIMARY KEY,
    location_id int
);

CREATE TABLE temperatures.alarm_logs_by_alarm (
    alarm_id timeuuid,
    id timeuuid,
    client_id timeuuid,
    location_id int,
    measurement double,
    message text,
    PRIMARY KEY (alarm_id, id)
) WITH CLUSTERING ORDER BY (id DESC);

CREATE TABLE temperatures.users (
    username text PRIMARY KEY,
    created_at timestamp,
    current_sign_in_at timestamp,
    current_sign_in_ip text,
    default_client_id timeuuid,
    deleted_at timestamp,
    email text,
    encrypted_password text,
    is_admin boolean,
    last_sign_in_at timestamp,
    last_sign_in_ip text,
    name text,
    problem_report_method text,
    pushover text,
    reading_error_interval int,
    remember_created_at timestamp,
    reset_password_sent_at timestamp,
    reset_password_token text,
    sign_in_count int,
    updated_at timestamp
);

CREATE MATERIALIZED VIEW temperatures.locations_by_client AS SELECT id, client_id FROM locations WHERE client_id IS NOT NULL PRIMARY KEY (client_id, id);
