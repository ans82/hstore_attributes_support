# encoding: UTF-8

# a class that includes this module will get the ability to set up virtual
# attributes stored in hstore columns very easily.
# E.g.: Consider a Person class with two hstore columns named "work_details" and
# "address". This class will upon includion of this module get two new methods
# named: work_details_hstore_accessor and address_hstore_accessor.
# These methods can be used on class level (like attr_accessor) to set up
# getter and setter methods for virtual attributes stored in these hstore
# columns. Additionally it will allow you to give a type hint and default values
# along. So new instances will use an "after_initialize" callback set up their
# hstore'd attributes to the default value which was provided, as well as
# being ale to return values typecasted (hstore data looses its type and is
# returned as a string otherwise...)
#
# Usage:
#
# class User < ActiveRecord::Base    # id: int, name: string, data :hstore, ...
#
#   include HstoreAttributes
#
#   data_hstore_accessor :age, :integer
#   data_hstore_accessor :salary, :float, 1234.56
#   data_hstore_accessor :admin, :boolean, false
#   data_hstore_accessor :icq, lambda{|n| n.blank? ? 'UIN: n/a' : "UIN: \##{n}"}
#
#  validates :salary, :numericality => {:greater_than => 2000}, :if => Proc.new { |p| p.admin? }
#
# end

module HstoreAttributeSupport
  extend ActiveSupport::Concern

  included do

    # define an class instance variable - different for each subclass, but the
    # same for each instance of these subclasses...
    # its a hash containing sym.-keys representing the "virtual attribute name"
    # and values which are hashes with :column, :cast, and :default values.
    #
    # :column defines the AR hstore column name where the attribute is stored
    # :type contains a symbol defining the type or a custom proc that converts
    #   the value in a user defined way
    # :default is the default value for this attribute
    #
    # An example for a person model with a "work_details" and "address" hstore
    # column could look like this:
    #
    # hstore_attributes => {
    #  :employer=>{:column => work_details, :type => :string,  :default => ""},
    #  :salary  =>{:column => work_details, :type => :integer, :default =>  0},
    #  :street  =>{:column => address,      :type => :string,  :default => ""},
    #  :city    =>{:column => address,      :type => :string,  :default => ""},
    # }
    #
    # thus, the model has four virtual attributes which are stored in two
    # differrent hstore columns.
    class << self; attr_accessor :hstore_attributes; end

    class_eval %Q{
      # this will set up an after_initialize callback allowing a new model
      # instance to set up default values for its hstore'd attributes.
      after_initialize do
        # iterate over the class instance variable "hstore_attributes", which
        # contains types & defaults for virtual hstore attributes and apply them
        (self.class.hstore_attributes || {}).each do |attr_name, settings|
          column      = settings[:column]
          default     = settings[:default]
          hstore_data = self.send(:"\#{column}") || {}
          hstore_data = { attr_name.to_s => default }.merge(hstore_data)
          self.send(:"\#{column}=", hstore_data)
        end
      end
    }

    # now we autogenerates convenient hstore_attr_accessor delegates, which can
    # be used to set up this models hstore'd attributes more rails like.
    # A Person class with a data hstore column could setup its name like this:
    #
    # data_hstore_accessor :name, :string, ''
    #
    # Which will set up accessors to the virtual attribute "name", defaults to
    # an empty string and is stored in the data column.
    # These methods are actually only syntactic sugar for the hstore_attr_accessor
    # method.
    columns.each do |column|
      next unless column.type == :hstore
      class_eval %Q{
        def self.#{column.name}_hstore_accessor(attribute_name, cast = nil, default = nil)
          return hstore_attr_accessor(attribute_name, "#{column.name}", cast, default)
        end
      }
    end

    # this class method allows descendant classes to set up attributes, which are
    # stored in a hstore column. this solves two problems:
    # 1. by providing a cast hint, it will take care of the data type, which is
    #    lost by the hstore and was a pure string otherwise
    # 2. it provides an easy way of setting up defaults, as rails AR mechanisms
    #    fail here (no database defaults available for virtual attributes)
    def self.hstore_attr_accessor(attribute_name, hstore_column, type  = nil, default = nil)
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

    private

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
    end

  end

end
