# frozen_string_literal: true

get 'operations' => 'operations#index'
get 'operations/list' => 'operations#list'
post 'operations' => 'operations#create', as: :add_operations_project
delete 'operations' => 'operations#destroy', as: :remove_operations_project
