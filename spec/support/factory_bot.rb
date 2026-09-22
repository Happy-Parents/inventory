RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

FactoryBot::SyntaxRunner.class_eval do
  include ActionDispatch::TestProcess
  include ActiveSupport::Testing::FileFixtures
end
