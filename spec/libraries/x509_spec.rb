require 'spec_helper'
require 'eassl'

describe "x509::x509", :type => 'library' do

  before(:all) do
    search = flexmock('search') do |m|
      m.should_receive(:search).with_any_args()
    end
    flexmock(Chef::Search::Query).should_receive(:new).and_return(search)
    subject # init subject
  end

  it "should generate a new private key" do
    x509_generate_key(2048).class.should == EaSSL::Key
  end

  it "should load a key from PEM format" do
    pem = <<EOPEM
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAw4R+I2P/DHimXbdsOUuq5KtQftmv4el7OjOzxPlHbksZggLX
eTbaiXb+ly+BQBRUeQaV4T6bNzNIfWrZ1RRstNmhDpIuObbUEVg2Z5nBTI/OAXd9
WbLqrJpdNgIVxwEKbKQhJzt+gPt29jtIlvz6zBUwOir3xiuU2WcyGAXYiuwwLAff
/gxTgX7Ooa0A55fVzoa3x2DNdRr58oznEmIVK41xEoeuCkKAVOtwsKtiX7/nKoD9
jbpA/d6sfoGzc020EojISMeiGm+dVxiFtDeSZtFQkc1zswKqAMA0wcwlrK3Uh3CL
Vs0n+Z4bMtbs1iPBIC9R7zr88c1WL2brNMY8XwIDAQABAoIBAQCvCwWrRbFoRvQb
X0ZDHZ2IUGAm0VoIFfK/Lt65cLwk4JObtFOZMCUDgUd5r4w2BH2ERQMWv+hSyVUT
BAC2Ji0U1Oq+kt1Tyn2eca1zn1JR60VyRrow/l/f2+urmL5KhoIAtgkAiOE/NONS
m8zncOJQqH+e9C0UfJws75kHrOQrqquzPRQ+RA+cw0IQjYZIVumzWp1Ty0lmk4I+
3cEPEVBklvh58nUATPhgT9KB2T/hc0+vZ8MplO4Wf/T8HBttC8Ry7k2ORmY/JeBz
1Bk1gLz9UDKozfQoVhCCYZ+GONUXs53690Bdg8VMkHbAzP++6ShzCJzor5oM5ido
fF8BWl5hAoGBAPIqHY1p2TLq/r4iOJNRGWIX9au+sajhQcU9yK6U86EAX2J+sU6f
HTmhSCkLja4i7iYT2oD62vIXiFZr4nGGsvVuErMYMD8BG/dyrO9UBROGRqJZDUye
sD4x+E1wuBJbLH2j5NPgt1KPQkmUvt1S6UYTuSVz/VhJI9pa7OkkXcdJAoGBAM6w
HxVVK08lrzMdjrve/GEd0nbXMf7Ym1enIKGaGqQjDMVIQ7vcQ2Mkum+B81ktQ5vH
6pnIehGH7+2RVImI9HptQ88iLQe2K6zUs7an2SDuSfwZNiTV4pmivT/Tuaqei6wv
StlgaKrxlKNR1AdlzMBwPanK3W8PeRh/P7plrJ5nAoGBAO9tLGLQsGpjZRJfi0g7
+ri9r6vqkoTCkeCNwYi6xFX+pFAhqvRs5NxB1bKfNalh58vF/VdgrnCFS8sGR5Cu
+Oknt11TIQBp/FifDNRjYdF4BQYmvbtvehlEFpeaRqP/ePGPxYKmvxnlgkh1xG/W
tcUPYxLgpy9OwR/2nh20UvPhAoGAcTeCX1Ie/iTbWnmXZQvZXW1TiyuHxFxsg1AW
DM94Rm64oRxblf0qoJVO1qPtY+zqetvAg2qQiyfWYmDYWNo/aQyPN1g2KGI+fFaq
9qPsySAeQMyinvzWOmgtmFfm/TIJulDRhE9OJk1cqTW6mi7GQKd675YjQ6HLKIMT
qovlSYMCgYEAkQ3yqBAtTl7HyDgWX5QHEt5wuXDvaJ6/ikXZES69cxij8eYTf2Ss
lahTFUqYdT22IAGxSxM2tffTgfB9RYkKtgwnhnZTl1QsjqpcW8QzEYyJGxcVEojl
KCM05kgFEFDb9ZWhNBFZeB6CiAdADQ/P5zu7nzW2DX8hKuwyFMvyadA=
-----END RSA PRIVATE KEY-----
EOPEM
    flexmock(File).should_receive(:read).and_return(pem)
    key = x509_load_key('file')
    key.class.should == EaSSL::Key
    key.length.should == 2048
  end

  it "should generate a csr given a key and a DN" do
    key = x509_generate_key(1024)
    name = {
      :common_name => 'cn',
      :city => 'city',
      :state => 'state',
      :email => 'email@example.com',
      :country => 'GB',
      :department => 'Dept',
      :organization => 'O'
    }
    csr = x509_generate_csr(key, name)
    csr.class.should == EaSSL::SigningRequest
  end

  it "should issue a self signed cert given a csr and a CA DN" do
    name = {
      :common_name => 'cn',
      :city => 'city',
      :state => 'state',
      :email => 'email@example.com',
      :country => 'GB',
      :department => 'Dept',
      :organization => 'O'
    }
    key = x509_generate_key(2048)
    csr = x509_generate_csr(key, name)
    cert, ca = x509_issue_self_signed_cert(csr, 'server', name)
    cert.class.should == EaSSL::Certificate
    ca.class.should == EaSSL::CertificateAuthority
  end

  it "should spot mismatched key and cert" do
    cert = <<EOPEM
-----BEGIN CERTIFICATE-----
MIIDcjCCAtugAwIBAgIBADANBgkqhkiG9w0BAQUFADBvMQswCQYDVQQGEwJHQjEP
MA0GA1UECAwGTG9uZG9uMQ8wDQYDVQQHDAZMb25kb24xEjAQBgNVBAoMCVZlbmRh
IEx0ZDEXMBUGA1UECwwOU1NMIEF1dG9tYXRpb24xETAPBgNVBAMMCFJTcGVjIENB
MB4XDTEyMDcwNjA3MjYwOFoXDTIyMDcwNDA3MjYwOFowbzELMAkGA1UEBhMCR0Ix
DzANBgNVBAgMBkxvbmRvbjEPMA0GA1UEBwwGTG9uZG9uMRIwEAYDVQQKDAlWZW5k
YSBMdGQxFzAVBgNVBAsMDlNTTCBBdXRvbWF0aW9uMREwDwYDVQQDDAhSU3BlYyBD
QTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA0HmgN6+qVAuhXDyfQdL9kb/v
RA4rMm9Vg/LA0lkRpXrT+E6rGokzA9VAJDwYXJFDNbh1REZQfJcJwFKmNhlFLFZy
3/quDuhf3MNON8f8vMp78l82NOETg4Gql0YUIgFdpNRcJGzmpkujzn12yH/g/PbO
JFhz2qmkRm1TXII7k98CAwEAAaOCARwwggEYMA8GA1UdEwEB/wQFMAMBAf8wOgYJ
YIZIAYb4QgENBC0WK1J1YnkvT3BlblNTTC9jaGVmLXNzbCBHZW5lcmF0ZWQgQ2Vy
dGlmaWNhdGUwHQYDVR0OBBYEFPZ4LnLseK1UUQh21oNTjOXYw51BMA4GA1UdDwEB
/wQEAwIBBjCBmQYDVR0jBIGRMIGOgBT2eC5y7HitVFEIdtaDU4zl2MOdQaFzpHEw
bzELMAkGA1UEBhMCR0IxDzANBgNVBAgMBkxvbmRvbjEPMA0GA1UEBwwGTG9uZG9u
MRIwEAYDVQQKDAlWZW5kYSBMdGQxFzAVBgNVBAsMDlNTTCBBdXRvbWF0aW9uMREw
DwYDVQQDDAhSU3BlYyBDQYIBADANBgkqhkiG9w0BAQUFAAOBgQAVcsXUcJixnjVn
+m4c8SHCpZPIUbiT8B36K+ah0gS9wD617z2s5I8Q1pO4O218yhb//SsTzz30srai
QIRQHddz0MeFU2Yc+sSHXROmZJPqBEXB75tlsIhSRqe+PUdEYRPtXw1DzHy4ntig
9goRCG0/OrvBbaIne3aroNXf78hlQw==
-----END CERTIFICATE-----
EOPEM

    key = <<EOPEM
-----BEGIN RSA PRIVATE KEY-----
MIICXgIBAAKBgQDksWBEnL8l9GLHuSq+bbdCvxltEbspCI/iwPncWwJ5yOhZftXH
uHYpw/prz6o0Rpmp3fv64qTNoZhXjCqfQ64BU3PoKPHyDcKGoQjYmbFS4N7+zB/j
ja1l9Jgr/c87TaNT7PY0+o7W7THfIXuyQV2LgnAO1jqoTaqE7NebdlopXQIDAQAB
AoGAF2d7tang+g5nqY7uq+xoi+EoxfvBjrJ8nzUmnQGHYFVKShZr5HOhTCbtUuk+
vvjWswavyf415YF7KMKEfiYcAX8qcobwx0VH2Vc5I6JUmrYYpdFG+fpOP1bUjTFW
2Eq8h69NCyXtI9lqlyPyA5Traj7FaJlSvpMpJ6JquBxC08ECQQD8RofKAbjKeFZv
9PdIMCzgbuvZioJF9D00cemFCCyOcl8/EqET7BhsHqzqgJuYRyuEUxKE+MIiXUoh
DJO/SmQtAkEA6BG3MNGHFlw37/FheOLIiX0+4hBtaDwXuWXPbzIZB8Hn5ikayqWT
xZJasRPqnazLAvlSUpSJ/pPtNvVW6qsn8QJBAIG3OmcST5Q8ICXdDbFepBSatEbd
Q3L4zOfEktBGjbKI+JST3aNCyKP/eeXyTw8TuTqHBIS+7AODeHRZ5TZ859kCQQDW
8PGXSbmwwCEfH5aD/Kh4j4RapZRv4pimouGJwADm6nX6+z9RSiKf73oIYMYA3DX7
vyi8S8+z9xbSvFGQcI5BAkEA6UhFMC7LdIG+4llZBf/AarqVi6hXL5f2bKi94Toi
A4UptyxGgz6+00trae6Ezc0S18oO70T16iSMI61OBh5Pxw==
-----END RSA PRIVATE KEY-----
EOPEM
    x509_verify_key_cert_match(key, cert).should be_false
  end

end
