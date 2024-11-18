# frozen_string_literal: true

require 'yaml'

module Gitlab
  module I18n
    include Gitlab::Utils::StrongMemoize
    extend self

    AVAILABLE_LANGUAGES = {
      'bg' => 'Bulgarian - български',
      'cs_CZ' => 'Czech - čeština',
      'da_DK' => 'Danish - dansk',
      'de' => 'German - Deutsch',
      'en' => 'English',
      'eo' => 'Esperanto - esperanto',
      'es' => 'Spanish - español',
      'fil_PH' => 'Filipino',
      'fr' => 'French - français',
      'gl_ES' => 'Galician - galego',
      'id_ID' => 'Indonesian - Bahasa Indonesia',
      'it' => 'Italian - italiano',
      'ja' => 'Japanese - 日本語',
      'ko' => 'Korean - 한국어',
      'nb_NO' => 'Norwegian (Bokmål) - norsk (bokmål)',
      'nl_NL' => 'Dutch - Nederlands',
      'pl_PL' => 'Polish - polski',
      'pt_BR' => 'Portuguese (Brazil) - português (Brasil)',
      'ro_RO' => 'Romanian - română',
      'ru' => 'Russian - русский',
      'si_LK' => 'Sinhalese - සිංහල',
      'tr_TR' => 'Turkish - Türkçe',
      'uk' => 'Ukrainian - українська',
      'zh_CN' => 'Chinese, Simplified - 简体中文',
      'zh_HK' => 'Chinese, Traditional (Hong Kong) - 繁體中文 (香港)',
      'zh_TW' => 'Chinese, Traditional (Taiwan) - 繁體中文 (台灣)'
    }.freeze
    private_constant :AVAILABLE_LANGUAGES

    # Languages with less then MINIMUM_TRANSLATION_LEVEL% of available translations will not
    # be available in the UI.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/221012
    MINIMUM_TRANSLATION_LEVEL = 2

    TRANSLATION_INFO_FILE_PATH = Rails.root.join('data/i18n/translation_info.yml')
    private_constant :TRANSLATION_INFO_FILE_PATH

    TRANSLATION_LEVEL_FIELD_NAME = 'translation_level'
    private_constant :TRANSLATION_LEVEL_FIELD_NAME

    def selectable_locales(minimum_translation_level = MINIMUM_TRANSLATION_LEVEL)
      AVAILABLE_LANGUAGES.reject do |code, _name|
        percentage_translated_for(code) < minimum_translation_level
      end
    end

    def percentage_translated_for(code)
      translation_levels.fetch(code, { TRANSLATION_LEVEL_FIELD_NAME => 0 })[TRANSLATION_LEVEL_FIELD_NAME]
    end

    def trimmed_language_name(code)
      language_name = AVAILABLE_LANGUAGES[code]
      return if language_name.blank?

      language_name.sub(/\s-\s.*/, '')
    end

    def available_locales
      AVAILABLE_LANGUAGES.keys
    end

    def locale
      FastGettext.locale
    end

    def locale=(locale_string)
      requested_locale = locale_string || ::I18n.default_locale
      new_locale = FastGettext.set_locale(requested_locale)
      ::I18n.locale = new_locale
    end

    def use_default_locale
      FastGettext.set_locale(::I18n.default_locale)
      ::I18n.locale = ::I18n.default_locale
    end

    def with_locale(locale_string)
      original_locale = locale

      self.locale = locale_string
      yield
    ensure
      self.locale = original_locale
    end

    def with_user_locale(user, &block)
      with_locale(user&.preferred_language, &block)
    end

    def with_default_locale(&block)
      with_locale(::I18n.default_locale, &block)
    end

    def setup(domain:, default_locale:)
      custom_pluralization
      setup_repositories(domain)
      setup_default_locale(default_locale)
    end

    private

    def custom_pluralization
      Gitlab::I18n::Pluralization.install_on(FastGettext)
    end

    def setup_repositories(domain)
      translation_repositories = [
        (po_repository(domain, 'jh/locale') if Gitlab.jh?),
        po_repository(domain, 'locale')
      ].compact

      FastGettext.add_text_domain(
        domain,
        type: :chain,
        chain: translation_repositories,
        ignore_fuzzy: true
      )

      FastGettext.default_text_domain = domain
    end

    def po_repository(domain, path)
      FastGettext::TranslationRepository.build(
        domain,
        path: Rails.root.join(path),
        type: :po,
        ignore_fuzzy: true
      )
    end

    def setup_default_locale(locale)
      FastGettext.default_locale = locale
      FastGettext.default_available_locales = available_locales
      ::I18n.available_locales = available_locales
    end

    def translation_levels
      YAML.load_file(TRANSLATION_INFO_FILE_PATH)
    end
    strong_memoize_attr :translation_levels
  end
end
