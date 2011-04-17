require 'eloqua/remote_object'

module Eloqua
  
  class Entity < RemoteObject
    
    self.remote_group = :entity

    def list_memberships
      self.class.list_memberships(id)
    end

    def add_membership(asset)
      asset.add_member(self)
    end

    def remove_membership(asset)
      asset.remove_member(self)
    end

    class << self

      def list_memberships(id)
        api.list_memberships(remote_object_type, id)
      end

      # This method does ~NOT~ sanitize input like active record does
      def build_query(where)
        if(where.is_a?(String))
          where
        elsif(where.is_a?(Hash))
          parts = []
          where.each do |attr, value|
            parts << "#{eloqua_attribute(attr)}='#{value}'"
          end
          parts.join(" AND ")
        end
      end

      def where(conditions, fields = [], limit = 200, page = 1)
        xml_query = api.builder do |xml|
          xml.eloquaType do
            xml.template!(:object_type, remote_object_type)
          end
          xml.searchQuery(build_query(conditions))
          xml.pageNumber(page)
          xml.pageSize(limit)
        end

        result = api.request(:query, xml_query)
        if(result[:entities])
          records = []
          result = result[:entities]
          if(result[:dynamic_entity].is_a?(Hash))
            result[:dynamic_entity] = [result[:dynamic_entity]]
          end
          result = result[:dynamic_entity]
          result.each do |entity|
            record_attrs = {}
            entity_id = entity[:id]
            entity[:field_value_collection][:entity_fields].each do |entity_attr|
              record_attrs[entity_attr[:internal_name]] = entity_attr[:value]
            end
            record_attrs[primary_key] = entity_id
            records << self.new(record_attrs, :remote)
          end
          records
        else
          false
        end
      end      
    end
    
  end
end