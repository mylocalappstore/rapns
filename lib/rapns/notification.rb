module Rapns
  class Notification < ActiveRecord::Base
    set_table_name "rapns_notifications"

    validates :device_token, :presence => true, :format => { :with => /^[a-z0-9]{64}$/ }
    validates :badge, :numericality => true, :allow_nil => true
    validates :expiry, :numericality => true, :presence => true

    validates_with Rapns::BinaryNotificationValidator

    scope :ready_for_delivery, lambda { where(:delivered => false, :failed => false).merge(where("deliver_after IS NULL") | where("deliver_after < ?", Time.now)) }

    def device_token=(token)
      write_attribute(:device_token, token.delete(" <>")) if !token.nil?
    end

    def attributes_for_device=(attrs)
      raise ArgumentError, "attributes_for_device must be a Hash" if !attrs.is_a?(Hash)
      write_attribute(:attributes_for_device, ActiveSupport::JSON.encode(attrs))
    end

    def attributes_for_device
      ActiveSupport::JSON.decode(read_attribute(:attributes_for_device)) if read_attribute(:attributes_for_device)
    end

    def as_json
      json = ActiveSupport::OrderedHash.new
      if mdm then
        json['mdm'] = mdm
      else
        json['aps'] = ActiveSupport::OrderedHash.new
        json['aps']['alert'] = alert if alert
        json['aps']['badge'] = badge if badge
        json['aps']['sound'] = sound if sound
        attributes_for_device.each { |k, v| json[k.to_s] = v.to_s } if attributes_for_device
      end
      json
    end

    # This method conforms to the enhanced binary format.
    # http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingWIthAPS/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW4
    def to_binary(options = {})
      id_for_pack = options[:for_validation] ? 0 : id
      json = as_json.to_json
      [1, id_for_pack, expiry, 0, 32, device_token, 0, json.size, json].pack("cNNccH*cca*")
    end
  end
end