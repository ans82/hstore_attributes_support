require "hstore_attribute_support/bootstrap"
require "hstore_attribute_support/base"

# Attach ourselves to ActiveRecord
if defined?(ActiveRecord::Base)
  ActiveRecord::Base.extend HstoreAttributeSupport::Bootstrap
end