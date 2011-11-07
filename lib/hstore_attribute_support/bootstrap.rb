# encoding: UTF-8

module HstoreAttributeSupport

  module Bootstrap
    def has_hstore_columns?
      false
    end

    def has_hstore_columns
      unless self.include? HstoreAttributeSupport::Base
        self.send :include, HstoreAttributeSupport::Base
      end
    end
  end

end
