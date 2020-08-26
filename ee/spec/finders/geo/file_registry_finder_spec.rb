# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::FileRegistryFinder, :geo do
  context 'with abstract methods' do
    %w[
      registry_class
    ].each do |required_method|
      it "requires subclasses to implement #{required_method}" do
        expect { subject.send(required_method) }.to raise_error(NotImplementedError)
      end
    end
  end
end
