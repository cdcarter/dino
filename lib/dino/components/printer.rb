# This component controls the AdaFruit Thermal Printer.
# Pick one up at --> http://www.adafruit.com/products/597
# These printers use TTL serial to communicate, 2 pins are required.

# Written by Christian Carter
# Ported from the C++ library by Limor Fried/Ladyada for Adafruit 
# Industries, in turn based on Thermal library from bildr.org 

# MIT license, all text above must be included in any redistribution.



module Dino
  module Components
  	class Printer < Core::MultiPin
  		# Most printers are standard configured for 19200. A few work at 9600.
  		# If your's does, don't worry, just pass a baud rate.
  		BAUDRATE = 19200

  		# Number of seconds to issue one byte to the printer. 11 bits to 
  		# account for idle, start, and stop bits.
  		# The AdaFruit library used a setTimeout sorta situation but for now
  		# we are just going to sleep().
  		BYTE_TIME = (11.to_f  / BAUDRATE)

  		# This amount will sleep 10 times on a wake command.
			WAKE_INCREMENT = 0.5

  		attr_accessor :baud, :timeout, :dot_print_time, :dot_feed_time,
  									:prev_byte, :column, :max_column, :char_height,
  									:line_spacing, :barcode_height

  		def after_initialize(options)
  			options[:baud] ||= BAUDRATE
  			@baud = options[:baud]
  			@serial = SoftwareSerial.new(board:self.board, pins: self.pins, baud: self.baud)
  			reset_state	
  		end

  		# set up all the important variables for printing.
  		def reset_state
  			@prev_byte = '\n'
  			@column = 0
  			@max_column = 32
  			@char_height = 24
  			@line_spacing = 8
  			@barcode_height = 50
  			@dot_feed_time = 2100
  			@dot_print_time = 30000
  		end

  		# reset the printer to its starting state as well as reset our 
  		# variables used for tracking
  		def reset
  			reset_state
  			write_bytes(27,64)
  		end

  		# set the default printing parameters
  		def default
  			# online
  			# justify :left
  			# inverse :off
  			# double_height :off
  			# line_height = 32
  			# bold :off
  			# underline :off
  			# @barcode_height = 50
  			# size :standard
  		end

      def begin(heat_time=255)
        @timeout = 0.5
        wake
        reset

        # Description of print settings from page 23 of the manual:
        # ESC 7 n1 n2 n3 Setting Control Parameter Command
        # Decimal: 27 55 n1 n2 n3
        # Set "max heating dots", "heating time", "heating interval"
        # n1 = 0-255 Max printing dots, Unit (8dots), Default: 7 (64 dots)
        # n2 = 3-255 Heating time, Unit (10us), Default: 80 (800us)
        # n3 = 0-255 Heating interval, Unit (10us), Default: 2 (20us)
        # The more max heating dots, the more peak current will cost
        # when printing, the faster printing speed. The max heating
        # dots is 8*(n1+1).  The more heating time, the more density,
        # but the slower printing speed.  If heating time is too short,
        # blank page may occur.  The more heating interval, the more
        # clear, but the slower printing speed.

        write_bytes(27,55)        # Esc 7 (print settings)
        write_bytes(20)           # Heating dots (20=balance of darkness vs no jams)
        write_bytes(heat_time)    # Library default = 255 (max)
        write_bytes(250)          # Heat interval (500 uS = slower, but darker)

        # Description of print density from page 23 of the manual:
        # DC2 # n Set printing density
        # Decimal: 18 35 n
        # D4..D0 of n is used to set the printing density.  Density is
        # 50% + 5% * n(D4-D0) printing density.
        # D7..D5 of n is used to set the printing break time.  Break time
        # is n(D7-D5)*250us.
        # (Unsure of the default value for either -- not documented)

        print_density = 14
        print_break_time = 4

        write_bytes(18,35) # DC2 # (print density)
        write_bytes((printBreakTime << 5) | printDensity)

        @dot_feed_time = 2100
        @dot_print_time = 30000

      end

  		# this is our very low level write-a-byte method for all high-level
  		# printing.
  		def write(byte)
  			if (byte != 0x13)
  				timeout_wait
  				write_bytes(byte)
  				wait = BYTE_TIME
  				if((byte == '\n') || (@column == @max_column))
  					wait += (@prev_byte == '\n') ? ((@char_height+@line_spacing) * @dot_feed_time) :
  																					((@char_height*@dot_print_time)+(@line_spacing*@dot_feed_time))
  					@column = 0
  					byte = '\n'
  				else
  					@column += 1
  				end
  				@timeout = wait
  				@prev_byte = byte
  			end
  		end

  		# sometimes the printer goes to sleep, we want to wake it up.
  		# the manual recommends 50ms delay, but we're gonna do 5 full sec
  		# with no-ops spaced in between. cause...better safe than sorry
  		def wake
  			@timeout = 0
  			write_bytes(255)
  			(1..10).each do |i| 
  				write_bytes(27)
  				@timeout = WAKE_INCREMENT
  			end
  		end

  		# this is our janky port of the timeout method.
  		# this can be made more ruby-ish.
  		def timeout_wait
  			sleep(@timeout)
  		end

  		# write some arbitrary bytes to the printer. the AdaFruit library
  		# only allowed for up to four bytes at a time but we're gonna not
  		# impose that restriction, yet.
  		# 
  		# this should be used for sending configuration commands/bitmaps
  		# they aren't for writing text.
  		def write_bytes(*bytes)
  			timeout_wait
  			bytes.each {|b| @serial.print(b)}
  			self.timeout = BYTE_TIME*bytes.length
  		end
  	end
  end
 end
