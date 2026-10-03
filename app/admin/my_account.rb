ActiveAdmin.register_page 'My Account' do
  menu priority: 100, label: proc { current_admin.email }

  content title: 'My Account' do
    telegram_logo = <<~SVG.html_safe
      <svg class="h-5 w-5 shrink-0" viewBox="0 0 24 24" aria-hidden="true">
        <path fill="#2AABEE" d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z"/>
      </svg>
    SVG

    done_icon = <<~SVG.html_safe
      <svg class="h-5 w-5 shrink-0 text-green-500" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
        <path fill-rule="evenodd" clip-rule="evenodd" d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z"/>
      </svg>
    SVG

    panel %(<span class="inline-flex items-center gap-2">#{telegram_logo}Telegram integration</span>).html_safe do
      if current_admin.telegram_id?
        div class: 'space-y-4' do
          div class: 'flex items-center gap-2' do
            text_node done_icon
            span "Connected as @#{current_admin.telegram_username}", class: 'font-medium'
          end
          text_node button_to('Disconnect Telegram',
                              admin_my_account_disconnect_telegram_path,
                              method: :delete,
                              data: { confirm: 'Disconnect Telegram integration' },
                              class: 'inline-flex h-9 items-center justify-center rounded-md ' \
                                     'bg-red-600 px-3 text-sm font-medium text-white ' \
                                     'hover:bg-red-700 active:bg-red-800 ' \
                                     'focus:outline-none focus:ring-2 focus:ring-red-500/40 ' \
                                     'dark:bg-red-500 dark:hover:bg-red-400')
        end
      else
        para 'Not connected. Click button below. ' \
             'Follow instructions. Find message in "Telgram" system chat. '
        div do
          # same widget as the login page; while signed in,
          # the callback links instead of logging in
          render 'admin/telegram_widget'
        end
      end
    end
  end

  page_action :disconnect_telegram, method: :delete do
    current_admin.update!(telegram_id: nil, telegram_username: nil)
    redirect_to admin_my_account_path, notice: 'Telegram disconnected.'
  end
end
