# frozen_string_literal: true

module Overcommit::Hook::PrePush
  # Runs `rubocop` over the whole repository before pushing.
  #
  # Overcommit ships no built-in pre-push RuboCop hook, and an ad hoc hook
  # (one defined purely by a `command` in .overcommit.yml) is not usable here:
  # ad hoc hooks append the pre-push arguments -- the remote name and URL -- to
  # the command, and RuboCop would treat them as paths to inspect.
  class RuboCop < Base
    def run
      result = execute(command)
      return :pass if result.success?

      [ :fail, result.stdout + result.stderr ]
    end
  end
end
