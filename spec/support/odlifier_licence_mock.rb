RSpec.shared_context 'odlifier licence mock', shared_context: :metadata do
  before(:each) do
    allow(Odlifier::License).to receive(:define).with("cc-by") {
      obj = double(Odlifier::License)
      allow(obj).to receive(:title) { "Creative Commons Attribution 4.0" }
      allow(obj).to receive(:id) { "CC-BY-4.0" }
      allow(obj).to receive(:url) { "https://example.org" }
      obj
    }
    allow(Odlifier::License).to receive(:define).with("cc-by-sa") {
      obj = double(Odlifier::License)
      allow(obj).to receive(:title) { "Creative Commons Attribution Share-Alike 4.0" }
      allow(obj).to receive(:id) { "CC-BY-SA-4.0" }
      allow(obj).to receive(:url) { "https://example.org" }
      obj
    }
    allow(Odlifier::License).to receive(:define).with("cc0") {
      obj = double(Odlifier::License)
      allow(obj).to receive(:title) { "CC0 1.0" }
      allow(obj).to receive(:id) { "CC0-1.0" }
      allow(obj).to receive(:url) { "https://example.org" }
      obj
    }
    allow(Odlifier::License).to receive(:define).with("OGL-UK-3.0") {
      obj = double(Odlifier::License)
      allow(obj).to receive(:title) { "Open Government Licence 3.0 (United Kingdom)" }
      allow(obj).to receive(:id) { "OGL-UK-3.0" }
      allow(obj).to receive(:url) { "https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/" }
      obj
    }
    allow(Odlifier::License).to receive(:define).with("odc-by") {
      obj = double(Odlifier::License)
      allow(obj).to receive(:title) { "Open Data Commons Attribution License 1.0" }
      allow(obj).to receive(:id) { "ODC-BY-1.0" }
      allow(obj).to receive(:url) { "https://example.org" }
      obj
    }
    allow(Odlifier::License).to receive(:define).with("odc-pddl") {
      obj = double(Odlifier::License)
      allow(obj).to receive(:title) { "Open Data Commons Public Domain Dedication and Licence 1.0" }
      allow(obj).to receive(:id) { "ODC-PDDL-1.0" }
      allow(obj).to receive(:url) { "https://example.org" }
      obj
    }
    allow(Odlifier::License).to receive(:define).with("ODbL-1.0") {
      obj = double(Odlifier::License)
      allow(obj).to receive(:title) { "Open Data Commons Open Database License 1.0" }
      allow(obj).to receive(:id) { "ODbL-1.0" }
      allow(obj).to receive(:url) { "https://example.org" }
      obj
    }
  end
end
