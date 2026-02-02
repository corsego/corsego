# frozen_string_literal: true

# Monkey-patch to fix Ransack 4.4.1 compatibility with Rails 8.1
# Rails removed the `table_name` alias from Arel::Table in favor of just `name`
# See: https://github.com/activerecord-hackery/ransack/issues/1420
#
# TODO: Remove this file when upgrading to Ransack 4.5+ which includes the fix
# The fix on main branch: relation.respond_to?(:table_name) ? relation.table_name : relation.name
module Arel
  class Table
    alias table_name name unless method_defined?(:table_name)
  end
end
