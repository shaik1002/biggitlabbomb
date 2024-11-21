# frozen_string_literal: true

module DashboardHelper
  include IconsHelper

  def has_start_trial?
    false
  end

  def feature_entry(title, href: nil, enabled: true, doc_href: nil)
    enabled_text = enabled ? 'on' : 'off'
    label = "#{title}: status #{enabled_text}"
    link_or_title = href && enabled ? tag.a(title, href: href) : title

    tag.p(aria: { label: label }) do
      concat(link_or_title)

      concat(tag.span(class: %w[light gl-float-right]) do
        boolean_to_icon(enabled)
      end)

      if doc_href.present?
        link_to_doc = link_to(
          sprite_icon('question-o'),
          doc_href,
          class: 'gl-ml-2',
          title: _('Documentation'),
          target: '_blank',
          rel: 'noopener noreferrer'
        )

        concat(link_to_doc)
      end
    end
  end

  def user_groups_requiring_reauth
    []
  end
end

DashboardHelper.prepend_mod_with('DashboardHelper')
