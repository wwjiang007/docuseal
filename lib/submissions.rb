# frozen_string_literal: true

module Submissions
  module_function

  def update_template_fields!(submission)
    submission.template_fields = submission.template.fields
    submission.template_schema = submission.template.schema
    submission.template_submitters = submission.template.submitters if submission.template_submitters.blank?

    submission.save!
  end

  def create_from_emails(template:, user:, emails:, source:, mark_as_sent: false)
    emails = emails.to_s.scan(User::EMAIL_REGEXP) unless emails.is_a?(Array)

    emails.map do |email|
      submission = template.submissions.new(created_by_user: user, source:, template_submitters: template.submitters)
      submission.submitters.new(email:,
                                uuid: template.submitters.first['uuid'],
                                sent_at: mark_as_sent ? Time.current : nil)

      submission.tap(&:save!)
    end
  end

  def create_from_submitters(template:, user:, submissions_attrs:, source:, mark_as_sent: false)
    submissions_attrs.map do |attrs|
      submission = template.submissions.new(created_by_user: user, source:, template_submitters: template.submitters)

      attrs[:submitters].each_with_index do |submitter_attrs, index|
        uuid =
          submitter_attrs[:uuid].presence ||
          template.submitters.find { |e| e['name'] == submitter_attrs[:role] }&.dig('uuid') ||
          template.submitters[index]&.dig('uuid')

        next if uuid.blank?

        submission.submitters.new(email: submitter_attrs[:email],
                                  phone: submitter_attrs[:phone].to_s.gsub(/[^0-9+]/, ''),
                                  name: submitter_attrs[:name],
                                  sent_at: mark_as_sent && submitter_attrs[:email].present? ? Time.current : nil,
                                  values: submitter_attrs[:values] || {},
                                  uuid:)
      end

      submission.tap(&:save!)
    end
  end
end
