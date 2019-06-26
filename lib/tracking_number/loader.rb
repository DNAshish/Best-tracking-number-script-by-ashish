
module TrackingNumber
  module Loader
    class << self
      def load_tracking_number_data
        tracking_number_types = []

        Dir.glob(File.join(File.dirname(__FILE__), "../data/couriers/*.json")).each do |file|
          courier_info          = read_courier_info(file)

          courier_info[:tracking_numbers].each do |tracking_info|
            tracking_name = tracking_info[:name]
            klass         = create_class(klass, courier_info, tracking_info)

            # Do some basic checks on the data file
            throw 'missing test numbers' unless has_test_numbers?(tracking_info)
            throw 'missing regex match groups' unless test_numbers_return_required_groups?(tracking_info, Regexp.new(klass::VERIFY_PATTERN))

            const = register_class(klass, tracking_name)
            tracking_number_types.push(const)
          end
        end

        TrackingNumber.const_set("TYPES", tracking_number_types)
      end

      private

      def has_test_numbers?(tracking)
        return tracking[:test_numbers] && tracking[:test_numbers][:valid]
      end

      def test_numbers_return_required_groups?(tracking, regex)
        test_number = tracking[:test_numbers][:valid][0]
        matches = test_number.match(regex)

        return matches["SerialNumber"]
      end

      def read_courier_info(file)
        return JSON.parse(File.read(file)).deep_symbolize_keys!
      end

      def create_class(klass, courier_info, tracking_info)
        klass = Class.new(TrackingNumber::Base)
        klass.const_set("COURIER_CODE", courier_info[:courier_code])
        info = courier_info.dup
        info.delete(:tracking_numbers)
        klass.const_set("COURIER_INFO", info)

        pattern = tracking_info[:regex]
        pattern = tracking_info[:regex].join if tracking_info[:regex].is_a?(Array)

        verify_pattern = "^#{pattern}$"
        search_pattern = "\\b#{pattern}\\b"

        klass.const_set("SEARCH_PATTERN", Regexp.new(search_pattern))
        klass.const_set("VERIFY_PATTERN", Regexp.new(verify_pattern))

        klass.const_set("VALIDATION", tracking_info[:validation])
        klass.const_set("ADDITIONAL", tracking_info[:additional])
        klass.const_set("TRACKING_URL", tracking_info[:tracking_url])

        return klass
      end

      def register_class(klass, tracking_name)
        klass_name = tracking_name.gsub(/[^0-9A-Za-z]/, '')
        return TrackingNumber.const_set(klass_name, klass)
      end
    end
  end
end
