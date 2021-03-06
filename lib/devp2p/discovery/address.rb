# -*- encoding : ascii-8bit -*-

require 'ipaddr'
require 'resolv'

module DEVp2p
  module Discovery

    class Address

      attr :udp_port, :tcp_port

      def self.from_endpoint(ip, udp_port, tcp_port="\x00\x00")
        new(ip, udp_port, tcp_port, true)
      end

      def initialize(ip, udp_port, tcp_port=nil, from_binary=false)
        tcp_port ||= udp_port

        if from_binary
          raise ArgumentError, "invalid ip" unless [4,16].include?(ip.size)

          @udp_port = dec_port udp_port
          @tcp_port = dec_port tcp_port
        else
          raise ArgumentError, "udp_port must be Integer" unless udp_port.is_a?(Integer)
          raise ArgumentError, "tcp_port must be Integer" unless tcp_port.is_a?(Integer)

          @udp_port = udp_port
          @tcp_port = tcp_port
        end

        begin
          @ip = from_binary ? IPAddr.new_ntoh(ip) : IPAddr.new(ip)
        rescue IPAddr::InvalidAddressError => e
          ips = Resolv.getaddresses(ip).sort {|addr| addr =~ /:/ ? 1 : 0 } # use ipv4 first
          raise e if ips.empty?
          @ip = ips[0]
        end
      end

      def ip
        @ip.to_s
      end

      def update(addr)
        @tcp_port = addr.tcp_port if @tcp_port.nil? || @tcp_port == 0
      end

      ##
      # addresses equal if they share ip and udp_port
      #
      def ==(other)
        [ip, udp_port] == [other.ip, other.udp_port]
      end

      def to_s
        "Address(#{ip}:#{udp_port})"
      end

      def to_h
        {ip: ip, udp_port: udp_port, tcp_port: tcp_port}
      end

      def to_b
        [@ip.hton, enc_port(udp_port), enc_port(tcp_port)]
      end
      alias to_endpoint to_b

      private

      def enc_port(p)
        Utils.int_to_big_endian4(p)[-2..-1]
      end

      def dec_port(b)
        Utils.big_endian_to_int(b)
      end

    end

  end
end
