require 'eloqua/api'

module Eloqua
  
  class Api
    class Service

      class << self

        delegate :builder, :remote_object_type, :to => Eloqua::Api
        
        def entity_association_xml(asset_type, asset_id, entity, entity_id)
          xml_query = builder do |xml|
            xml.template!(:object, :entity, entity, entity_id)
            xml.template!(:object, :asset, asset_type, asset_id)
          end
        end

        # Delegate Group
        def key_with_object(group, name)
          if (group == :entity)
            name.to_sym
          else
            parts = name.to_s.split('_')
            "#{parts[0]}_#{group}_#{parts[1]}".to_sym
          end
        end

        # Delegate Group
        def object_method(group, method)
          if (group == :entity)
            method.to_sym
          else
            "#{method}_#{group}".to_sym
          end
        end

        def request(*args)
          Eloqua::Api.request(:service, *args)
        end

        # Delegate, Group, Type
        def create_object(group, type, attributes)
          xml_query = builder do |xml|
            xml.object_collection!(group) do
              xml.dynamic_object!(group) do
                xml.template!(:dynamic, group, type, nil, attributes)
              end
            end
          end

          result = request(object_method(group, :create), xml_query)
          result = result[key_with_object(group, :create_result)]

          if (result[:errors].nil? && result[:id])
            {:id => result[:id].to_i}
          else
            handle_exception(result)
          end
        end

        # Delegate Group, Type
        def update_object(group, type, entity_id, attributes)
          xml_query = builder do |xml|
            xml.object_collection!(group) do
              xml.dynamic_object!(group) do
                xml.template!(:dynamic, group, type, entity_id, attributes)
              end
            end
          end

          result = request(object_method(group, :update), xml_query)
          result = result[key_with_object(group, :update_result)]

          if (result[:success] && result[:id].to_s == entity_id.to_s)
            true
          else
            handle_exception(result)
          end
        end

        # Delegate Group, Type
        def delete_object(group, type, id)
          xml_query = builder do |xml|
            xml.object_type_lower!(group) do
              xml.template!(:object_type, type)
            end
            xml.ids do
              xml.template!(:int_array, [id])
            end
          end

          result = request(object_method(group, :delete), xml_query)
          result = result[key_with_object(group, :delete_result)]

          if (result[:success] && result[:id].to_s == id.to_s)
            [result[:id]]
          else
            handle_exception(result)
          end
        end

        # Delegate Group, Type
        def find_object(group, type, id)
          xml_query = builder do |xml|
            xml.object_type_lower!(group) do
              xml.template!(:object_type, type)
            end
            xml.ids do
              xml.template!(:int_array, [id])
            end
          end


          result = request(object_method(group, :retrieve), xml_query)

          field_key = "#{group}_fields".to_sym
          dynamic_key = "dynamic_#{group}".to_sym

          if (result[dynamic_key] && result[dynamic_key][:field_value_collection])
            attribute_list = result[dynamic_key][:field_value_collection][field_key]
            attributes = {:id => result[dynamic_key][:id].to_i}
            attribute_list.each do |map|
              attributes[map[:internal_name].to_sym] = map[:value]
            end
            attributes
          else
            false
          end
        end

        # Delegate Type
        def list_memberships(entity_type, entity_id)
          xml_query = builder do |xml|
            xml.template!(:object, :entity, entity_type, entity_id)
          end
          results = request(:list_group_membership, xml_query)
          results = results[:dynamic_asset]
          results.inject([]) do |map, object|
            map << object[:asset_type]
            map
          end
        end

        def entity_asset_operation(request_method, asset_type, asset_id, entity, entity_id)
          xml_query = entity_association_xml(asset_type, asset_id, entity, entity_id)
          result = request(request_method.to_sym, xml_query)
          if (result[:success])
            true
          elsif (result[:errors])
            handle_exception(result)
          else
            false
          end
        end

        def add_group_member(asset_type, asset_id, entity_type, entity_id)
          entity_asset_operation(:add_group_member, asset_type, asset_id, entity_type, entity_id)
        end

        def remove_group_member(asset_type, asset_id, entity_type, entity_id)
          entity_asset_operation(:remove_group_member, asset_type, asset_id, entity_type, entity_id)
        end

        # Delegate Group
        def list_types(group)
          types = "#{group}_types".to_sym
          result = request("list_#{types}".to_sym)
          if (result && result[types])
            result[types][:string]
          end
        end

        # Delegate Group, Type
        def describe(group, type)
          xml_query = builder do |xml|
            xml.object_type_lower!(group) do
              xml.template!(:object_type, type)
            end
          end
          remote_method = "describe_#{group}".to_sym
          result = request(remote_method, xml_query)
          if (result)
            field_describe_key = "dynamic_#{group}_field_definition".to_sym
            fields = result[:fields]
            if (fields.is_a?(Hash) && fields.has_key?(field_describe_key))
              result[:fields] = fields[field_describe_key]
            end
          end
          result
        end

        # Delegate Group, Type
        def describe_type(group, type_name)
          key_type = "#{group}_type".to_sym
          key_types = "#{key_type}s".to_sym

          if(group == :entity)
            type_name_key = :global_entity_type
          else
            type_name_key = key_type
          end
          result = request("describe_#{group}_type".to_sym, type_name_key => type_name)
          Eloqua.format_results_for_array(result, key_types, key_type)
        end

        def handle_exception(response)
          exception = response[:errors][:error]

          error_code = exception[:error_code]
          message = exception[:message]

          error_message = sprintf("Eloqua Error: Code (%s) | Message: %s", error_code, message)

          if (error_code =~ /Duplicate/)
            raise(Eloqua::DuplicateRecordError, error_message)
          else
            raise(Eloqua::RemoteError, error_message)
          end
          false

        end

      end

    end

  end

end
