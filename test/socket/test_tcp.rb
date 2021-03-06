begin
  require "socket"
  require "test/unit"
rescue LoadError
end


class TestSocket_TCPSocket < Test::Unit::TestCase
  def test_initialize_failure
    # These addresses are chosen from TEST-NET-1, TEST-NET-2, and TEST-NET-3.
    # [RFC 5737]
    # They are choosen because probably they are not used as a host address.
    # Anyway the addresses are used for bind() and should be failed.
    # So no packets should be generated.
    test_ip_addresses = [
      '192.0.2.1', '192.0.2.42', # TEST-NET-1
      '198.51.100.1', '198.51.100.42', # TEST-NET-2
      '203.0.113.1', '203.0.113.42', # TEST-NET-3
    ]
    begin
      list = Socket.ip_address_list
    rescue NotImplementedError
      return
    end
    test_ip_addresses -= list.reject {|ai| !ai.ipv4? }.map {|ai| ai.ip_address }
    if test_ip_addresses.empty?
      return
    end
    client_addr = test_ip_addresses.first
    client_port = 8000

    server_addr = '127.0.0.1'
    server_port = 80

    begin
      # Since client_addr is not an IP address of this host,
      # bind() in TCPSocket.new should fail as EADDRNOTAVAIL.
      t = TCPSocket.new(server_addr, server_port, client_addr, client_port)
      flunk "expected SystemCallError"
    rescue SystemCallError => e
      assert_match "for \"#{client_addr}\" port #{client_port}", e.message
    end
  ensure
    t.close if t && !t.closed?
  end

  def test_recvfrom
    svr = TCPServer.new("localhost", 0)
    th = Thread.new {
      c = svr.accept
      c.write "foo"
      c.close
    }
    addr = svr.addr
    sock = TCPSocket.open(addr[3], addr[1])
    assert_equal(["foo", nil], sock.recvfrom(0x10000))
  ensure
    th.kill if th
    th.join if th
  end

  def test_encoding
    svr = TCPServer.new("localhost", 0)
    th = Thread.new {
      c = svr.accept
      c.write "foo\r\n"
      c.close
    }
    addr = svr.addr
    sock = TCPSocket.open(addr[3], addr[1])
    assert_equal(true, sock.binmode?)
    s = sock.gets
    assert_equal("foo\r\n", s)
    assert_equal(Encoding.find("ASCII-8BIT"), s.encoding)
  ensure
    th.kill if th
    th.join if th
    sock.close if sock
  end
end if defined?(TCPSocket)
