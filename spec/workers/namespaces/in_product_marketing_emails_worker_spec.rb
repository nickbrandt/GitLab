# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::InProductMarketingEmailsWorker, '#perform' do
  using RSpec::Parameterized::TableSyntax

  # Running these tests in EE would call the overriden method, which we can't test in CE.
  # EE is covered in a separate EE spec.
  unless Gitlab.ee?
    context 'not on gitlab.com' do
      let(:is_gitlab_com) { false }

      where(:in_product_marketing_emails_enabled, :experiment_active, :executes_service) do
        true     | true     | 1
        true     | false    | 1
        false    | false    | 0
        false    | true     | 0
      end

      with_them do
        it_behaves_like 'in-product marketing email'
      end
    end
  end

  context 'on gitlab.com' do
    let(:is_gitlab_com) { true }

    where(:in_product_marketing_emails_enabled, :experiment_active, :executes_service) do
      true     | true     | 1
      true     | false    | 0
      false    | false    | 0
      false    | true     | 0
    end

    with_them do
      it_behaves_like 'in-product marketing email'
    end
  end
end
