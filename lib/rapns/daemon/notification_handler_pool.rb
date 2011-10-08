module Rapns
  module Daemon
    class NotificationHandlerPool < Pool

      protected

      def new_object_for_pool(i)
        NotificationHandler.new
      end

      def object_added_to_pool(object)
        object.start
      end

      def object_removed_from_pool(object)
        object.stop
      end

      def drain_started
        @num_objects.times { Rapns::Daemon.notification_queue.push(Rapns::Daemon::NotificationHandler::STOP) }
      end
    end
  end
end