# encoding: UTF-8

require 'active_support/concern'

module HstoreAttributeSupport

  module Base
    
    extend ActiveSupport::Concern

    included do
      def self.has_hstore_columns?
        true
      end

      class_attribute :hstore_attributes
      
      # now we autogenerate convenient hstore_attr_accessor delegates, which can
      # be used to set up this models hstore'd attributes more rails like.
      # A Person class with a data hstore column could setup its name like this:
      #
      # data_hstore_accessor :name, :string, ''
      #
      # Which will set up accessors to the virtual attribute "name", defaults to
      # an empty string and is stored in the data column.
      # These methods are actually only syntactic sugar for the
      # hstore_attr_accessor method.
      self.columns.each do |column|
        next unless column.type == :hstore
        class_eval %Q{
          def self.#{column.name}_hstore_accessor(attribute_name, cast = nil, default = nil)
            return hstore_attr_accessor(attribute_name, "#{column.name}", cast, default)
          end
        }
      end

      # this will set up an after_initialize callback allowing a new model
      # instance to set up default values for its hstore'd attributes.
      after_initialize do
        # iterate over the class instance variable "hstore_attributes", which
        # contains types & defaults for virtual hstore attributes and apply them
        (self.class.hstore_attributes || {}).each do |attr_name, settings|
          column      = settings[:column]
          default     = settings[:default]
          hstore_data = self.send(:"#{column}") || {}
          hstore_data = { attr_name.to_s => default }.merge(hstore_data)
          self.send(:"#{column}=", hstore_data)
        end
      end
    end

    module ClassMethods

      # this class method allows descendant classes to set up attributes, which
      # are stored in a hstore column. this solves two problems:
      # 1. by providing a cast hint, it will take care of the data type, which
      #    is lost by the hstore and was a pure string otherwise
      # 2. it provides an easy way to set up defaults, as rails AR mechanism
      #    fail here (no database defaults available for virtual attributes)
      def hstore_attr_accessor(attribute_name, hstore_column, type  = nil, default = nil)
        self.hstore_attributes ||= {}

        self.hstore_attributes[attribute_name.to_s] = {
          :column  => hstore_column.to_s,
          :type    => type,
          :default => default
        }

        class_eval %Q{
          def #{attribute_name}
            return read_hstore_attribute("#{attribute_name}")
          end

          def #{attribute_name}?
            return read_hstore_attribute("#{attribute_name}").present?
          end

          def #{attribute_name}=(value)
            return write_hstore_attribute("#{attribute_name}", value)
          end
        }
      end
    end

    module InstanceMethods
      
      def read_hstore_attribute(attribute_name)
        ha_column   = self.class.hstore_attributes[attribute_name][:column]
        ha_type     = self.class.hstore_attributes[attribute_name][:type]
        hstore_data = self.send(:"#{ha_column}").try(:with_indifferent_access)

        return nil unless hstore_data

        value = hstore_data[attribute_name]

        return value unless ha_type

        case ha_type
        when :integer
          return value.to_i
        when :float
          return value.to_f
        when :decimal
          return value.to_s.to_d
        when :boolean
          return !(value.to_s == '' || value.to_s == 'false')
        when :bool
          return !(value.to_s == '' || value.to_s == 'false')
        when :string
          return value.to_s
        when :datetime
          return value.to_s.to_datetime
        when :date
          return value.to_s.to_date
        else
        end

        return ha_type.call(value) if ha_type.is_a?(Proc)

        raise "read_hstore_attribute failed when trying to cast the type \"#{ha_type.inspect}\". Please define the type as one of [:integer, :float, :decimal, :boolean, :string, :datetime, :date] or pass in a lambda with one parameter to perform custom casts."
      end

      def write_hstore_attribute(attribute_name, value)
        ha_column   = self.class.hstore_attributes[attribute_name][:column]
        hstore_data = (self.send(:"#{ha_column}") || {}).with_indifferent_access
        hstore_data = hstore_data.merge({attribute_name => value})
        self.send(:"#{ha_column}=", hstore_data)
        self
      end

    end

  end
end
