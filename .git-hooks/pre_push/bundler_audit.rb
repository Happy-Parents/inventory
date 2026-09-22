# frozen_string_literal: true

module Overcommit::Hook::PrePush
  # Checks the bundle for gems with known vulnerabilities before pushing.
  #
  # See the note in rubo_cop.rb for why this is a plugin hook rather than an
  # ad hoc one defined in .overcommit.yml.
  class BundlerAudit < Base
    def run
      result = execute(command)
      return :pass if result.success?

      [ :fail, result.stdout + result.stderr ]
    end
  end
end
