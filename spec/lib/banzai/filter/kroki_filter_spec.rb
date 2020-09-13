# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::KrokiFilter do
  include FilterSpecHelper

  it 'replaces nomnoml pre tag with img tag' do
    stub_application_setting(kroki_enabled: true, kroki_url: "http://localhost:8000")
    doc = filter("<pre lang='nomnoml'><code>[Pirate|eyeCount: Int|raid();pillage()|\n  [beard]--[parrot]\n  [beard]-:>[foul mouth]\n]</code></pre>")

    expect(doc.to_s).to eq '<img src="http://localhost:8000/nomnoml/svg/eNqLDsgsSixJrUmtTHXOL80rsVLwzCupKUrMTNHQtC7IzMlJTE_V0KzhUlCITkpNLEqJ1dWNLkgsKsoviUUSs7KLTssvzVHIzS8tyYjligUAMhEd0g==">'
  end

  it 'does not replace nomnoml pre tag with img tag if disabled' do
    stub_application_setting(kroki_enabled: false)
    doc = filter("<pre lang='nomnoml'><code>[Pirate|eyeCount: Int|raid();pillage()|\n  [beard]--[parrot]\n  [beard]-:>[foul mouth]\n]</code></pre>")

    expect(doc.to_s).to eq "<pre lang=\"nomnoml\"><code>[Pirate|eyeCount: Int|raid();pillage()|\n  [beard]--[parrot]\n  [beard]-:&gt;[foul mouth]\n]</code></pre>"
  end
end
