require 'carto/db/migration_helper'

include Carto::Db::MigrationHelper

migration(
  Proc.new do
    run "DO $$
         DECLARE
         accounts text[] := (select array_agg(distinct(account_type)) from users where account_type not in (select account_type from account_types));

        BEGIN
          IF accounts IS NULL THEN
            RETURN;
          END IF;
          FOR i in 1 .. array_length(accounts, 1) LOOP
            WITH rate_limit AS (
              INSERT INTO rate_limits
                (maps_anonymous,
                maps_static,
                maps_static_named,
                maps_dataview,
                maps_dataview_search,
                maps_analysis,
                maps_tile,
                maps_attributes,
                maps_named_list,
                maps_named_create,
                maps_named_get,
                maps_named,
                maps_named_update,
                maps_named_delete,
                maps_named_tiles,
                maps_analysis_catalog,
                sql_query,
                sql_query_format,
                sql_job_create,
                sql_job_get,
                sql_job_delete)
              VALUES
                ('{2, 2, 1}',
                 '{1, 1, 1}',
                 '{2, 2, 1}',
                 '{1, 1, 1}',
                 '{1, 1, 1}',
                 '{1, 1, 1}',
                 '{30, 30, 1, 75, 150, 60}',
                 '{1, 1, 1}',
                 '{1, 1, 1}',
                 '{1, 1, 1}',
                 '{4, 4, 1}',
                 '{1, 1, 1}',
                 '{2, 2, 1}',
                 '{1, 1, 1}',
                 '{1, 1, 1}',
                 '{1, 1, 1}',
                 '{2, 2, 1}',
                 '{1, 1, 1}',
                 '{2, 2, 1}',
                 '{1, 1, 1}',
                 '{1, 1, 1}')
              RETURNING id)
            INSERT INTO account_types (account_type, rate_limit_id)
              VALUES (accounts[i], (select id from rate_limit));
          END LOOP;
        END $$;"
    alter_table :users do
      add_foreign_key [:account_type], :account_types, on_delete: :restrict, null: false
      add_index :account_type
    end
  end,
  Proc.new do
    alter_table :users do
      drop_constraint :users_account_type_fkey
      drop_index :account_type
    end
  end
)
