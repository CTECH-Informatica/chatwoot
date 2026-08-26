class SuperAdmin::SettingsController < SuperAdmin::ApplicationController
  def show; end

  def refresh
    # rubocop:disable Rails/I18nLocaleTexts
    if ChatwootHub.disabled?
      redirect_to super_admin_settings_path,
                  notice: 'Chatwoot Hub is disabled for this installation. Instance sync was not performed.'
    else
      Internal::CheckNewVersionsJob.perform_now
      redirect_to super_admin_settings_path, notice: 'Instance status refreshed'
    end
    # rubocop:enable Rails/I18nLocaleTexts
  end
end
