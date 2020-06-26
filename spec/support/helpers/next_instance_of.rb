# frozen_string_literal: true

module NextInstanceOf
  def expect_next_instance_of(klass, *new_args)
    stub_instantiation(expect(klass), :new, *new_args) do |expectation|
      yield(expectation)
    end
  end

  def allow_next_instance_of(klass, *new_args)
    stub_instantiation(allow(klass), :new, *new_args) do |allowance|
      yield(allowance)
    end
  end

  def expect_next_allocation_of(klass, *new_args)
    stub_instantiation(expect(klass), :allocate, *new_args) do |expectation|
      yield(expectation)
    end
  end

  def allow_next_allocation_of(klass, *new_args)
    stub_instantiation(allow(klass), :allocate, *new_args) do |allowance|
      yield(allowance)
    end
  end

  private

  def stub_instantiation(target, method, *new_args)
    receive_initialize = receive(method)
    receive_initialize.with(*new_args) if new_args.any?

    target.to receive_initialize.and_wrap_original do |method, *original_args|
      method.call(*original_args).tap do |instance|
        yield(instance)
      end
    end
  end
end
