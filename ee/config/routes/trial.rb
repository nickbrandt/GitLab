# frozen_string_literal: true

resources :trials, only: [:new] do
  collection do
    post :create_lead
  end
end
