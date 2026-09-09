class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

# Since UUIDs have no chronological order.
self.implicit_order_column = :created_at
end
