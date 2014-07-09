class UserNotifier::Base < ActiveRecord::Base
  self.abstract_class = true

  def self.notify_once(template_name, user, params = {})
    notify(template_name, user, params) if is_unique?(template_name, {self.user_association_name => user})
  end

  def self.notify(template_name, user, params = {})
    create!({
      template_name: template_name,
      locale: I18n.locale,
      from_email: UserNotifier.from_email,
      from_name: UserNotifier.from_name,
      self.user_association_name => user
    }.merge(params)).tap{|n| n.deliver }
  end

  def deliver
    deliver! unless self.sent_at.present?
  end

  def deliver!
    UserNotifier::EmailWorker.perform_async(self.class.name.to_s, self.id)
  end

  private
  def self.user_association_name
    UserNotifier.user_class_name.downcase.to_sym
  end

  belongs_to user_association_name

  def self.is_unique?(template_name, filter)
    filter.nil? || self.where(filter.merge(template_name: template_name)).empty?
  end
end

