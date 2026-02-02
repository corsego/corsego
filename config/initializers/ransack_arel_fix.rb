# frozen_string_literal: true

# Monkey-patch to fix Ransack compatibility with Rails 8.1
# Rails removed the `table_name` alias from Arel::Table in favor of just `name`
# See: https://github.com/activerecord-hackery/ransack/issues/1420
module Arel
  class Table
    alias table_name name unless method_defined?(:table_name)
  end
end
