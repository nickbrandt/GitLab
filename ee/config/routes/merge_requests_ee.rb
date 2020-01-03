# frozen_string_literal: true

resources :merge_requests, only: [], constraints: { id: /\d+/ } do
  member do
    get '/descriptions/:version_id/diff', action: :description_diff, as: :description_diff
    get :metrics_reports
    get :license_management_reports
    get :container_scanning_reports
    get :dependency_scanning_reports
    get :sast_reports
    get :dast_reports

    get :approvals
    post :approvals, action: :approve
    delete :approvals, action: :unapprove

    post :rebase
  end

  resources :approvers, only: :destroy
  delete 'approvers', to: 'approvers#destroy_via_user_id', as: :approver_via_user_id
  resources :approver_groups, only: :destroy

  scope module: :merge_requests do
    resources :drafts, only: [:index, :update, :create, :destroy] do
      collection do
        post :publish
        delete :discard
      end
    end
  end
end
