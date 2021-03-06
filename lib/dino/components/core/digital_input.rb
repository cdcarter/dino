module Dino
  module Components
    module Core
      class DigitalInput < BaseInput
        HIGH = 1
        LOW = 0

        def initialize(options={})
          super(options)
          _listen
        end

        def _read
          board.digital_read(self.pin)
        end

        def _listen
          board.digital_listen(self.pin)
        end

        def on_high(&block)
          add_callback(:high) do |data|
            block.call(data) if data.to_i == HIGH
          end
        end

        def on_low(&block)
          add_callback(:low) do |data|
            block.call(data) if data.to_i == LOW
          end
        end
      end
    end
  end
end
