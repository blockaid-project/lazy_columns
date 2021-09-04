module LazyColumns
  module ActsAsLazyColumnLoader
    extend ActiveSupport::Concern

    module ClassMethods
      def lazy_load(*columns)
        return unless table_exists?
        columns = columns.collect(&:to_s)
        exclude_columns_from_default_scope columns
        define_lazy_accessors_for columns
      end

      private

      def exclude_columns_from_default_scope(columns)
        default_scope { select((column_names - columns).map { |column_name| "#{ActiveRecord::Base.connection.quote_table_name(table_name)}.#{ActiveRecord::Base.connection.quote_column_name(column_name)}" }) }
      end

      def define_lazy_accessors_for(columns)
        columns.each { |column| define_lazy_accessor_for column }
      end

      def define_lazy_accessor_for(column)
        define_method column do
          unless has_attribute?(column)
            changes_before_reload = self.changes.clone

            # Same as `self.reload` except without clearing the query cache;
            # taken from `activerecord/lib/active_record/persistence.rb`.
            fresh_object = self.class.unscoped { self.class.find(id) }
            @attributes = fresh_object.instance_variable_get("@attributes")
            @new_record = false

            changes_before_reload.each{|attribute_name, values| self.send("#{attribute_name}=", values[1])}
          end
          read_attribute column
        end
      end
    end
  end
end

if ActiveRecord::Base.respond_to?(:lazy_load)
  $stderr.puts "ERROR: Method `.lazy_load` already defined in `ActiveRecord::Base`. This is incompatible with LazyColumns and the plugin will be disabled."
else
  ActiveRecord::Base.send :include, LazyColumns::ActsAsLazyColumnLoader
end


