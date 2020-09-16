# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      ##
      # Factory class responsible for fabricating entry objects.
      #
      class Factory
        InvalidFactory = Class.new(StandardError)

        attr_reader :entry_class

        def initialize(entry_classes)
          @entry_classes = entry_classes
          @entry_class = Array(@entry_classes).one? ? Array(@entry_classes).first : nil
          @metadata = {}
          @attributes = entry_class ? { default: entry_class.default } : {}
        end

        def value(value)
          @value = value
          self
        end

        def metadata(metadata)
          @metadata.merge!(metadata.compact)
          self
        end

        def with(attributes)
          @attributes.merge!(attributes.compact)
          self
        end

        def description
          @attributes[:description]
        end

        def inherit
          @attributes[:inherit]
        end

        def inheritable?
          @attributes[:inherit]
        end

        def reserved?
          @attributes[:reserved]
        end

        def create!
          raise InvalidFactory unless defined?(@value)

          set_entry_class
          
          ##
          # We assume that unspecified entry is undefined.
          # See issue #18775.
          #
          if @value.nil?
            Entry::Unspecified.new(fabricate_unspecified)
          else
            fabricate(entry_class, @value)
          end
        end

        private

        def set_entry_class
          @entry_class = Array(@entry_classes).then do |klasses|
            if klasses.one?
              klasses.first
            else
              @attributes[:parent].class.find_type(@attributes[:key], @value)
            end
          end
        end

        def fabricate_unspecified
          ##
          # If entry has a default value we fabricate concrete node
          # with default value.
          #
          default = @attributes.fetch(:default)

          if default.nil?
            fabricate(Entry::Undefined)
          else
            fabricate(entry_class, default)
          end
        end

        def fabricate(entry_class, value = nil)
          entry_class.new(value, @metadata) do |node|
            node.key = @attributes[:key]
            node.parent = @attributes[:parent]
            node.default = @attributes[:default]
            node.description = @attributes[:description]
          end
        end
      end
    end
  end
end
