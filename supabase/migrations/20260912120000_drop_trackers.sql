-- Trackers were in-app + SQL seed only. There is no Google Sheet tab and no
-- CSV to delete. Apply after the UG pivot; do not edit that historical
-- migration.

drop function if exists public.tracker_completion(uuid);

drop table if exists public.user_tracker_item_done;
drop table if exists public.tracker_items;
drop table if exists public.trackers;

drop type if exists public.tracker_kind;
