hstore attribute support
========================

Enables AR models to set up virtual attributes stored in hstore columns.
The main problem with a naked hstore solution in rails is, that defaults
are not supported (no schema.rb that tells rails, what the default is) and the
types get lost when loading the serialized hstore data into a hash.
With hstore attribute support, you can wire up your models in a rails like
fashion very easily.

=== What it can do for you
Consider a Person class with two hstore columns named "work_details" and
"address". This class will, upon activation of the hstore attribute support, get
two new class methods: work_details_hstore_accessor and address_hstore_accessor.
Activating the support is done by just inserting the method call
"has_hstore_columns" into your AR class.

These methods can now be used (on AR class level, just like attr_accessor) to
set up getter/setter methods for virtual attributes that are stored in the
hstore columns.

Additionally you are able to give a type hint and default values along.
Because of that, new instances will be able (using an "after_initialize"
callback) to set up their hstore'd attributes to the default value you provided.
On top of this, the model obtains getter methods to return values typecasted
(hstore data looses its type and was returned as a string otherwise...).

**Example:**

    # Schema for User:
    # - id:   int
    # - name: string
    # - data: hstore
    class User < ActiveRecord::Base

      has_hstore_columns  # activates hstore support and mixes in the new methods

      # the explicit definition of a boolean attribute admin (stored in hstore
      # column 'data', initialized with default value false) looks like this:
      hstore_attr_accessor :admin, :boolean, false

      # however for each hstore column there are autogenerated prefixed methods:
      data_hstore_accessor :age,    :integer          # defaults to nil
      data_hstore_accessor :salary, :float,   1234.56 # with default value 1234.56

      # it is even possible to define a custom typecast via a lambda
      data_hstore_accessor :icq, lambda{|n| n.blank? ? 'UIN: n/a' : "UIN: \##{n}"}

      # as accessors get defined, validation and other stuff works out of the box:
      validates :salary,
        :numericality => {:greater_than => 2000},
        :if => Proc.new { |u| u.admin? }

    end
