namespace :active_admin do
  namespace :tailwind do
    input_css  = 'app/assets/tailwind/active_admin.css'
    output_css = 'app/assets/builds/active_admin.css'

    write_entrypoint = lambda do
      aa = Gem.loaded_specs['activeadmin']&.full_gem_path ||
           abort('active_admin:tailwind — activeadmin gem not found')

      contents = <<~CSS
        @import "tailwindcss";

        @plugin "#{aa}/plugin.js";

        @source "#{aa}/vendor/javascript/flowbite.js";
        @source "#{aa}/plugin.js";
        @source "#{aa}/app/views/**/*.{arb,erb,html,rb}";
        @source "../../admin/**/*.{arb,erb,html,rb}";
        @source "../../views/active_admin/**/*.{arb,erb,html,rb}";
        @source "../../views/admin/**/*.{arb,erb,html,rb}";
        @source "../../views/layouts/active_admin*.{erb,html}";
        @source "../../javascript/**/*.js";
      CSS

      dir = File.dirname(input_css)
      FileUtils.mkdir_p(dir)
      FileUtils.mkdir_p(File.dirname(output_css))
      File.write(input_css, contents)
    end

    tailwind_cmd = lambda do |extra|
      require 'tailwindcss/ruby'
      [ Tailwindcss::Ruby.executable, '-i', input_css, '-o', output_css, *extra ]
    end

    desc "Build ActiveAdmin's Tailwind CSS into app/assets/builds/active_admin.css"
    task build: :environment do
      write_entrypoint.call
      system(*tailwind_cmd.call([ '--minify' ]), exception: true)
    end

    desc "Watch and rebuild ActiveAdmin's Tailwind CSS on changes"
    task watch: :environment do
      write_entrypoint.call
      system(*tailwind_cmd.call([ '-w' ]), exception: true)
    end
  end
end

if Rake::Task.task_defined?('assets:precompile')
  Rake::Task['assets:precompile'].enhance([ 'active_admin:tailwind:build' ])
end
