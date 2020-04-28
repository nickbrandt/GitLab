# frozen_string_literal: true

require 'spec_helper'

describe Git::WikiPushService, services: true do
  include RepoHelpers

  let(:gl_repository) { "wiki-#{project.id}" }
  let(:key) { create(:key, user: current_user) }
  let(:key_id) { key.shell_id }
  let_it_be(:project) { create(:project, :wiki_repo) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:git_wiki) { project.wiki.wiki }
  let_it_be(:repository) { git_wiki.repository }
  let(:commit_details) { create(:git_wiki_commit_details, author: current_user) }

  # Any actions that need to happen before we capture the base_sha
  let(:setup) { nil }

  # We need to know the SHA before each example runs, hence the use of let-bang
  let!(:base_sha) do
    setup
    current_sha || Gitlab::Git::BLANK_SHA
  end

  describe '#execute' do
    context 'the push contains more than the permitted number of changes' do
      before do
        described_class::MAX_CHANGES.times { write_new_page }
        write_new_page
      end

      it 'creates only MAX_CHANGES events' do
        expect { execute_service }.to change(Event, :count).by(described_class::MAX_CHANGES)
      end
    end

    context 'default_branch collides with a tag' do
      before do
        write_new_page
      end

      it 'creates only one event' do
        changes = post_received(base_sha, ['refs/heads/master', 'refs/tags/master']).changes
        service = described_class.new(project, current_user, changes: changes)

        expect { service.execute }.to change(Event, :count).by(1)
      end
    end

    context 'one creation, one update, one deletion' do
      let(:wiki_page_a) { create(:wiki_page, project: project) }
      let(:wiki_page_b) { create(:wiki_page, project: project) }
      let(:count) { Event::WIKI_ACTIONS.count }
      let(:setup) { wiki_page_a && wiki_page_b }

      before do
        write_new_page
        update_page(wiki_page_a.title)
        delete_page(wiki_page_b.page.path)
      end

      it 'creates two events' do
        expect { execute_service }.to change(Event, :count).by(count)
      end

      it 'handles all known actions' do
        execute_service

        expect(Event.last(count).pluck(:action)).to match_array(Event::WIKI_ACTIONS)
      end

      shared_examples 'a no-op push' do
        it 'does not create any events' do
          expect { execute_service }.not_to change(Event, :count)
        end

        it 'does not even look for events to process' do
          service = described_class.new(project, current_user, changes: post_received.changes)

          expect(service).not_to receive(:changed_files)

          service.execute
        end
      end

      context 'the wiki_events feature is disabled' do
        before do
          stub_feature_flags(wiki_events: false)
        end

        it_behaves_like 'a no-op push'
      end

      context 'the wiki_events_on_git_push feature is disabled' do
        before do
          stub_feature_flags(wiki_events_on_git_push: false)
        end

        it_behaves_like 'a no-op push'

        context 'but is enabled for a given project' do
          before do
            stub_feature_flags(wiki_events_on_git_push: { enabled: true, thing: project })
          end

          it 'creates events' do
            expect { execute_service }.to change(Event, :count).by(count)
          end
        end
      end
    end

    context 'two pages have been created' do
      before do
        write_new_page
        write_new_page
      end

      it 'creates two events' do
        expect { execute_service }.to change(Event, :count).by(2)
      end

      it 'creates two metadata records' do
        expect { execute_service }.to change(WikiPage::Meta, :count).by(2)
      end

      it 'creates appropriate events' do
        execute_service

        expect(Event.last(2)).to all(have_attributes(wiki_page?: true, action: Event::CREATED))
      end
    end

    context 'a non-page file as been added' do
      before do
        write_non_page
      end

      it 'does not create events, or WikiPage metadata' do
        expect { execute_service }.not_to change { [Event.count, WikiPage::Meta.count] }
      end
    end

    context 'one page, and one non-page have been created' do
      before do
        write_new_page
        write_non_page
      end

      it 'creates one events' do
        expect { execute_service }.to change(Event, :count).by(1)
      end

      it 'creates two metadata records' do
        expect { execute_service }.to change(WikiPage::Meta, :count).by(1)
      end

      it 'creates appropriate events' do
        execute_service

        expect(Event.last).to have_attributes(wiki_page?: true, action: Event::CREATED)
      end
    end

    context 'one page has been added, and then updated' do
      before do
        title = write_new_page
        update_page(title)
      end

      it 'creates just a single event' do
        expect { execute_service }.to change(Event, :count).by(1)
      end

      it 'creates just one metadata record' do
        expect { execute_service }.to change(WikiPage::Meta, :count).by(1)
      end

      it 'creates a new wiki page creation event' do
        execute_service

        expect(Event.last).to have_attributes(
          wiki_page?: true,
          action: Event::CREATED
        )
      end
    end

    context 'when a page we already know about has been updated' do
      let(:wiki_page) { create(:wiki_page, project: project) }
      let(:setup) { create(:wiki_page_meta, :for_wiki_page, wiki_page: wiki_page) }

      before do
        update_page(wiki_page.title)
      end

      it 'does not create a new meta-data record' do
        expect { execute_service }.not_to change(WikiPage::Meta, :count)
      end

      it 'creates a new event' do
        expect { execute_service }.to change(Event, :count).by(1)
      end

      it 'adds an update event' do
        execute_service

        expect(Event.last).to have_attributes(
          wiki_page?: true,
          action: Event::UPDATED
        )
      end

      context 'adding the event is not successful' do
        it 'calls log_error' do
          event_service = double(:event_service)
          error = ServiceResponse.error(message: 'something went very very wrong')
          service = described_class.new(project, current_user, changes: post_received.changes)
          allow(service).to receive(:event_service).and_return(event_service)
          allow(event_service).to receive(:execute).with(String, WikiPage, Integer).and_return(error)

          expect(service).to receive(:log_error).with(error.message)

          service.execute
        end
      end
    end

    context 'when a page we do not know about has been updated' do
      let(:wiki_page) { create(:wiki_page, project: project) }
      let(:setup) { wiki_page }

      before do
        update_page(wiki_page.title)
      end

      it 'creates a new meta-data record' do
        expect { execute_service }.to change(WikiPage::Meta, :count).by(1)
      end

      it 'creates a new event' do
        expect { execute_service(base_sha) }.to change(Event, :count).by(1)
      end

      it 'adds an update event' do
        execute_service

        expect(Event.last).to have_attributes(
          wiki_page?: true,
          action: Event::UPDATED
        )
      end
    end

    context 'when a page we do not know about has been deleted' do
      let(:wiki_page) { create(:wiki_page, project: project) }
      let(:setup) { wiki_page }

      before do
        delete_page(wiki_page.page.path)
      end

      it 'create a new meta-data record' do
        expect { execute_service }.to change(WikiPage::Meta, :count).by(1)
      end

      it 'creates a new event' do
        expect { execute_service(base_sha) }.to change(Event, :count).by(1)
      end

      it 'adds an update event' do
        execute_service

        expect(Event.last).to have_attributes(
          wiki_page?: true,
          action: Event::DESTROYED
        )
      end
    end
  end

  def execute_service(base = base_sha)
    changes = post_received(base).changes
    described_class.new(project, current_user, changes: changes).tap(&:execute)
  end

  def post_received(base = base_sha, refs = ['refs/heads/master'])
    change_str = refs.map { |ref| +"#{base} #{current_sha} #{ref}" }.join("\n")
    post_received = ::Gitlab::GitPostReceive.new(project, key_id, change_str, {})
    allow(post_received).to receive(:identify).with(key_id).and_return(current_user)

    post_received
  end

  def current_sha
    repository.gitaly_ref_client.find_branch('master')&.dereferenced_target&.id
  end

  def write_new_page
    commit_details = create(:git_wiki_commit_details, author: current_user)
    generate(:wiki_page_title).tap { |t| git_wiki.write_page(t, 'markdown', 'Hello', commit_details) }
  end

  # We write something to the wiki-repo that is not a page - as, for example, an
  # attachment. This will appear as a raw-diff change, but wiki.find_file will
  # return nil.
  def write_non_page
    params = {
      file_name: 'attachment.log',
      file_content: 'some stuff',
      branch_name: 'master'
    }
    ::Wikis::CreateAttachmentService.new(project, project.owner, params).execute
  end

  def update_page(title)
    commit_details = create(:git_wiki_commit_details, author: current_user)
    page = git_wiki.page(title: title)
    git_wiki.update_page(page.path, title, 'markdown', 'Hey', commit_details)
  end

  def delete_page(path)
    git_wiki.delete_page(path, commit_details)
  end
end
