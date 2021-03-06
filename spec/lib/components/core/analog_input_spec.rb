require 'spec_helper'

module Dino
  module Components
    module Core
      describe AnalogInput do
        let(:txrx) { mock(:txrx, add_observer: true, handshake: 14, write: true, read: true) }
        let(:board) { Board.new(txrx) }
        let(:options) { { pin: 'A0', board: board } }
        subject { AnalogInput.new(options) }

        describe '#_read' do
          it 'should send #analog_read to the board with its pin' do
            board.should_receive(:analog_read).with(subject.pin)
            subject._read
          end
        end

        describe '#_listen' do
          it 'should send #analog_listen to the board with its pin' do
            board.should_receive(:analog_listen).with(subject.pin)
            subject._listen
          end
        end
      end
    end
  end
end
