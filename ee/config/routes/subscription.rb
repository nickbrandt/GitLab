# frozen_string_literal: true

resource :subscriptions, only: [:new] do
  get :payment_form
  get :payment_method
end
