# This component controls the AdaFruit Thermal Printer.
# Pick one up at --> http://www.adafruit.com/products/597
# These printers use TTL serial to communicate, 2 pins are required.

# Written by Christian Carter
# Ported from the C++ library by Limor Fried/Ladyada for Adafruit 
# Industries, in turn based on Thermal library from bildr.org 

# MIT license, all text above must be included in any redistribution.



module Dino
  module Components
  	class Printer
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
  			@baud = options.baud
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
  					column += 1
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
