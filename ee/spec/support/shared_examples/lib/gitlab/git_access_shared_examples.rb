# frozen_string_literal: true

RSpec.shared_examples 'a read-only GitLab instance' do
  it 'denies push access' do
    project.add_maintainer(user)

    expect { push_changes }.to raise_unauthorized("You can't push code to a read-only GitLab instance.")
  end

  context 'for a Geo setup' do
    let(:primary_node) { create(:geo_node, :primary, url: 'https://localhost:3000/gitlab') }

    before do
      allow(Gitlab::Geo).to receive(:primary).and_return(primary_node)
      allow(Gitlab::Geo).to receive(:secondary_with_primary?).and_return(secondary_with_primary)
    end

    context 'that is incorrectly set up' do
      let(:secondary_with_primary) { false }
      let(:error_message) { "You can't push code to a read-only GitLab instance." }

      it 'denies push access with primary present' do
        project.add_maintainer(user)

        expect { push_changes }.to raise_unauthorized(error_message)
      end
    end

    context 'that is correctly set up' do
      let(:secondary_with_primary) { true }
      let(:payload) do
        {
          'action' => 'geo_proxy_to_primary',
          'data' => {
            'api_endpoints' => %w{/api/v4/geo/proxy_git_push_ssh/info_refs /api/v4/geo/proxy_git_push_ssh/push},
            'primary_repo' => primary_repo_url
          }
        }
      end
      let(:console_messages) do
        [
          "You're pushing to a Geo secondary! We'll help you by proxying this",
          "request to the primary:",
          "",
          "  #{primary_repo_ssh_url}"
        ]
      end

      it 'attempts to proxy to the primary' do
        project.add_maintainer(user)

        expect(push_changes).to be_a(Gitlab::GitAccessResult::CustomAction)
        expect(push_changes.payload).to eql(payload)
        expect(push_changes.console_messages).to include(*console_messages)
      end
    end
  end
end
