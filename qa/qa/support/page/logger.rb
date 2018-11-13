# frozen_string_literal: true

module QA
  module Support
    module Page
      module Logger
        def refresh
          super

          log("refreshed #{current_url}")
        end

        def wait(max: 60, time: 0.1, reload: true)
          log("with wait: max #{max}; time #{time}; reload #{reload}")

          super

          log("end wait")
        end

        def scroll_to(selector, text: nil)
          log("scrolling to :#{selector}")

          super
        end

        def asset_exists?(url)
          exists = super

          log("asset_exists? #{url} returned #{exists}")

          exists
        end

        def find_element(name)
          element = super

          log("found :#{name}")

          element
        end

        def all_elements(name)
          elements = super

          log("found all :#{name}")

          elements
        end

        def click_element(name)
          super

          log("clicked :#{name}")
        end

        def fill_element(name, content)
          super

          content = '*****' if name.to_s.include? "password"

          log(%Q(filled :#{name} with "#{content}"))
        end

        def has_element?(name)
          found = super

          log("has_element? :#{name} returned #{found}")

          found
        end

        def within_element(name)
          log("within element :#{name}")

          super

          log("end within element :#{name}")
        end

        private

        def log(msg)
          puts "debug: #{msg}"
        end
      end
    end
  end
end
