-- Set session timeout to 1 minute for creating the MATERIALIZED VIEW
-- SET statement_timeout = 60000;

SELECT
    SUM(count) AS total_count,
    SUM(only_active) AS total_only_active,
    SUM(not_ghost) AS total_not_ghost,
    SUM(active_non_ghost_non_bot) AS active_non_ghost_non_bot,
    SUM(member_10_active_and_not_ghost_count) AS total_member_10_active_and_not_ghost_count,
    NOW() refresh_time
FROM(
      (
        SELECT
          COUNT(id) AS "count",
          SUM(CASE WHEN "users"."state" IN ('active') THEN 1 END) "only_active",
          SUM(CASE WHEN "users"."ghost" IS NOT TRUE THEN 1 END) "not_ghost",
          SUM(CASE WHEN ("users"."state" IN ('active'))
                        AND ("users"."ghost" IS NOT TRUE)
                        AND ("users"."bot_type" IS NULL)
                   THEN 1
                   END
              ) "active_non_ghost_non_bot",
          0 AS "member_10_active_and_not_ghost_count"
        FROM
          "users"
      )
      UNION ALL
      (
        SELECT
          0 AS "count",
          0 AS "only_active",
          0 AS "not_ghost",
          0 AS "active_non_ghost_non_bot",
          COUNT(DISTINCT "users"."id") AS "member_10_active_and_not_ghost_count"
        FROM
          "users"
        INNER JOIN
          "members"
          ON "members"."user_id" = "users"."id"
          WHERE ("users"."state" IN ('active'))
          AND ("users"."ghost" IS NOT TRUE)
          AND "users"."bot_type" IS NULL
          AND ("members"."access_level" > 10)
      )
) as x

-- Need UNIQUE INDEX to refresh MATERIALIZED VIEW concurrently
-- CREATE UNIQUE INDEX users_count_refresh_time ON users_count (refresh_time);
