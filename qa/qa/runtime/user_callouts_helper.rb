# frozen_string_literal: true

module QA
  module Runtime
    module UserCalloutsHelper
      module_function

      # Dismiss callouts/popovers like the UI itself does.
      # If this method is called before visiting the page where the
      # popver would appear, the popover won't be displayed.
      # This avoids the need to click a button to dismiss it (and all
      # the changes that would be required, e.g., adding a selector)
      def dismiss_callout(feature_name)
        Runtime::Logger.debug("Sending request to disable popover '#{feature_name}'")

        csrf_token = Capybara.page.evaluate_script("document.querySelector('meta[name=csrf-token]').content")

        Capybara.page.execute_script <<~JS
          xhr = new XMLHttpRequest();
          xhr.open('POST', '/-/user_callouts', true);
          xhr.setRequestHeader('Content-type', 'application/json');
          xhr.setRequestHeader('X-CSRF-Token', '#{csrf_token}');
          xhr.send('{"feature_name":"#{feature_name}"}');
        JS

        request_done = Support::Waiter.wait do
          Capybara.page.evaluate_script('xhr.readyState == XMLHttpRequest.DONE')
        end

        unless request_done
          Runtime::Logger.debug("Request readyState did not transistion to DONE")
          return false
        end

        request_status = Capybara.page.evaluate_script('xhr.status').to_i

        unless request_status == 200
          Runtime::Logger.debug("Request returned status: #{request_status}")
          return false
        end

        true
      end
    end
  end
end
