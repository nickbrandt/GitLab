# frozen_string_literal: true

require 'spec_helper'

describe Operations::FeatureFlags::UserList do
  subject { create(:operations_feature_flag_user_list) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }
    it { is_expected.to validate_length_of(:name).is_at_least(1).is_at_most(255) }

    describe 'user_xids' do
      where(:valid_value) do
        ["", "sam", "1", "a", "uuid-of-some-kind", "sam,fred,tom,jane,joe,mike",
         "gitlab@example.com", "123,4", "UPPER,Case,charActeRS", "0",
         "$valid$email#2345#$%..{}+=-)?\\/@example.com", "spaces allowed",
         "a" * 256, "a,#{'b' * 256},ccc", "many    spaces"]
      end
      with_them do
        it 'is valid with a string of comma separated values' do
          user_list = described_class.create(user_xids: valid_value)

          expect(user_list.errors[:user_xids]).to be_empty
        end
      end

      where(:typecast_value) do
        [1, 2.5, {}, []]
      end
      with_them do
        it 'automatically casts values of other types' do
          user_list = described_class.create(user_xids: typecast_value)

          expect(user_list.errors[:user_xids]).to be_empty
          expect(user_list.user_xids).to eq(typecast_value.to_s)
        end
      end

      where(:invalid_value) do
        [nil, "123\n456", "1,2,3,12\t3", "\n", "\n\r",
         "joe\r,sam", "1,2,2", "1,,2", "1,2,,,,", "b" * 257, "1, ,2", "tim,    ,7", " ",
         "    ", " ,1", "1,  ", " leading,1", "1,trailing  ", "1, both ,2"]
      end
      with_them do
        it 'is invalid' do
          user_list = described_class.create(user_xids: invalid_value)

          expect(user_list.errors[:user_xids]).to include(
            'user_xids must be a string of unique comma separated values each 256 characters or less'
          )
        end
      end
    end
  end

  it_behaves_like 'AtomicInternalId' do
    let(:internal_id_attribute) { :iid }
    let(:instance) { build(:operations_feature_flag_user_list) }
    let(:scope) { :project }
    let(:scope_attrs) { { project: instance.project } }
    let(:usage) { :operations_user_lists }
  end
end
