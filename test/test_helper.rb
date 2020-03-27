# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
require "rails/test_help"
require "mocha/minitest"
require "webmock/minitest"

# Filter out the backtrace from minitest while preserving the one from other libraries.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

require "rails/test_unit/reporter"
Rails::TestUnitReporter.executable = "bin/test"

require_relative "../app/jobs/zaikio/jwt_auth/revoke_access_token_job"

class ActiveSupport::TestCase
  include Zaikio::JWTAuth::TestHelper

  def dummy_private_key
    OpenSSL::PKey::RSA.new(
      "-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: DES-EDE3-CBC,04E19DCC8FB00BB9

WbRLeqrkR/dItOBQbEe5qY4OfsPHkC3TS3Vp6DvCEAmz4ei+nkIaYXULQtANirkL
zoRJYfMuDgq3/dbnjOrPMQveU1odCcaCDY05xHVE3Dc0gI1BnwKSCfKKU8kuRUZB
T/Azsnb0AkAlmAukNMshuR/JrSN3qVX73oka00D035zq6rhJNYQ2MS2sBx39rZmJ
mYakBQWvhrM9Yp1IsghoR2wasaehasdnOSC2ceAU9IlEPs6KcQSbpaQ413tFNjjF
VH7NNYcUbQnSS/uiB1StSlcbvxNF1N2ZI9SUnUbwq2T992ckeEHuapaTh4yjnhsH
jYFnoIyXPLgSkYttLdmW1GLZjYkIyPaTbCci3GK474Fts6+cIFDjNmN1FP7e94Ue
OPYpRlHf7vrv9AlwlNVBpX9lsxAbWihOvYaL4YwMEEW5hurZ3FCXOcHar428waXE
y0wH9R45ktuVkPTOL16X3ja+9wKVtwVMzw7NTuUcnI8ed7bWUnE+JBRrPyRbR+jw
IRpAeECGv5Tubox2OweZQGca6E5nb22enD0i1bHL2gNBuNbkWBJAidF1btoJ+wB4
qibUr0ZZVzPQzVLrIICBRPFVrG1u43t1TAxP+3GoCFuwa1ibWpm9uGqrkBsxs4r5
bTfu55bFpmLNHNK1rbuus/sz8nEyhAuYrv0/kBfhgRBQdnZkvZST4TlzOfJDPiNi
jPPzlifZug5Tx3oC0znRLAm5/GDtxQazapZvPEt2eNoR54TcvAGuHN1FZRA4eL1o
+HmgtZyCW9ZFK5FDIXk5myVbxYgmGI6ynQ4OtnHl6Logdm5azMRnmlxPCF9i8UzQ
M8CIq/s8Xf9HQKMOXHu1SJcWM3QHJO0zl3lWJ671lJ83+tjlaWbjr0UuyBdZtvi6
FN3+sYkJlWOQ6ZcwJAYChnR5kweJVlPWd5qnNnr00AXln90W147uEQemneqeXwPM
3rFeQXGb36rBi1iP4kBwbWgxpGl/TkRcMkUbwX317kuvBHgtW9k8iSVz19nno1lC
hCsXSF0oH6qD0fzxiLfJto4GgiKX/nknB4QN3BFmXa76u+aLPtWF+5LWVCrgKjJ3
o6tbLetC0D7pBGr1/VZ2o83LMiq19G1WcHnNQXATEzZz7nitWu5ZGTusMZqdtEa1
tubw+n6BTN46Ayj2rLpt1V6o/+QDvu6asJMb1zkpkDLgMiI6LJ4KFbLlGh9Ov4/4
ElClg6whWAUgfjZfppjcxzlwUpcIMBmANV+pcrTSxrxqOC+paDIVDeZFuzvHbahi
gZRC7wAu+JORgB63S37ok3CxHlYSXL2d0RGYcVjUg3+bvNUpeuntfXdTMK54Gnxu
ejtCmVSfiDiCkJC8MJPfPUmnfSRNqBoKgJLzOtRypCxs9UD5afX/a398ZkcA4TmN
lAn7hvCIY2GzK/KmwfYdGinnbrBnjK0Ai7D6E/khd4lkUmQWwpdGWd2xI81XU5Vf
HFQZgfBzyai/+HgSciL9inShMFd+pXW1cDlG+2r66KULkNI2C3tKBMcRKpc+t3d3
S7y/D9aF96X6pnnSOZz2GcK7T0eLAsKgYOnAKRXUvo1jG0MgktB51Q==
-----END RSA PRIVATE KEY-----",
      "test"
    ).freeze
  end

  def other_dummy_private_key
    OpenSSL::PKey::RSA.new(
      "-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: DES-EDE3-CBC,888CDE34840326DB

47L4BizukWNDzF7kWG5+tn4n7fNSEfjF+T1dEBtycFi2KUrgOSrzIVsZqp30wkcK
J7nf+5HikFiT/ffyL+Pfa/IyIHcmvu92xADFguTu3P1h1xFABg+hTvYahLq/mM8K
OyvV3x3ht1iNWoBRB/9HkpfdCo7/AZ4YGYEH9QqJGZhaMhMc5iO1e16AFC9Fhjtq
XTOkDxcPCs/u3jBpthfWx12Mb+o7aZa7bKa173/IV4VL0v93OnMHfM25yq5V12Kz
O0WANgsWh6+MrEueoR7fuL/4EePfe34tuCetMJ5WKA5hk8rIF2SMV3JcBULB+kp+
YCSNAnpSLqzPCxGMNiHrEm3JlqtPOgEeNQeZVkut8EcSW9oae8FNWp4y+bov1VHZ
6V4ZjA5O1ol2w88JaJ+/W1K5vCr77Gle6v7jJpPG5ZKaAh1HZCYtd7i+9qMHZ/5a
fC5iOZnyhWEuO7oFZO1MPGlC+1LRsLP2OgODn+DENlhcykiCfe0FMqe8iPVmhWYo
SwxpD//uqP3bYBlRrJsbLVrHSOcUc/kS0l/xssWRccxAgU18jxSR/Tax1MWEzCtw
q9W9oN8bYwMN4MSoXrxeGyFIWFcsGdfEgueSfPAFUeCCDj/U97Pa/bSlx2DrJKue
jPJQ5/Qjd7iqYgomYOSk92lrkYVoLBPTzDRzOT5qgHv+YJbIZBjTW193Eau6ld3y
6Lb5oF/ErWg8YTm8SFFnKuQVPfOGpOB2/YeYRxEWNulYZ0BU12V0Cva+P6j7D5HW
d9sWNKInoG9b8HAP7JnZtK0AkgDoy10+DP0cgWzfKbtfEj/0eIAoBx4PZ579Jn4v
PFaKVjVs5mndnH1exLkGH8DkiXJJAld+gYbVsTM2BkpvnCEMWPyIfLy4+eNIBcHn
IfioNalv/YGDLu67+L2lR2mVRtWi8qjTEDgJVvw3zisq9oPTj4Au9rvy1AkmsW3q
WMTsgbyt/gvEex+b8sa9Hs4XohOPEgFx794/xP7KT7SY23yEYpMcRq0zzdU6XrbP
hmZaE4d8EN0vpEo6c1z9NoN4sm2NR0RHWKn/02uBdNI2FeQDR4Dn/FmWl1q6BuVU
xV/PLVtnE36ep9g2hfcT6reJWJWR9A1oV168LGbSKL1NeLFA9eYjZbBJf7z7KEPY
Yi1IOZbLBOdxSGWXw5D07BsGXZhZm6hMWbPjsB4USMs7JShpyG9EAv8YEJJ003t+
+OO6jTf70dtqfpBfM1zPRNILdWS07CpyzZ4zvxzcVJ3CiWQgpsQUDJkQyT/WPh5q
3bKozAefsxEDrNZNIBHFusR1hyR7E2hw2SkS217suz/hgDnEOyH3DAx6EIFJJhe3
dhVF4lKETU81vrMd7sBk4I3mmAq+UezLystnS2NrNOPZ1wJDqPMxZWzQYdKtBnbr
7yBTpesqLfdxxEFaufW6pDHTLod2tn78C21Eu8ghHRMPkHeXubdh40Jm4nZSSvHF
hIo+Ga1hKLZfs2/EMTe+BzmIvQTap0iiOP8XYmtDZ87pjA5n5pRnRWtZ3OQk+sqa
i15NDU2sOtIV5ZgaraNIP8o8+KybAdj15shKrsm3nFTJMLScg1KLOA==
-----END RSA PRIVATE KEY-----",
      "test"
    ).freeze
  end

  def generate_token(extra_payload = {}, private_key = nil)
    private_key ||= dummy_private_key
    payload = {
      iss: "CP",
      sub: "Organization/123",
      aud: %w[directory test_app],
      jti: "unique-token-id",
      nbf: Time.now.to_i,
      exp: 1.hour.from_now.to_i,
      jku: "http://directory.zaikio.test/api/v1/jwt_public_keys.json",
      scope: ["directory.organization.r", "test_app.resources.r"]
    }.merge(extra_payload)

    JWT.encode(payload, private_key, "RS256", kid: JWT::JWK.new(private_key).kid)
  end

  def stub_requests
    stub_request(:get, "http://directory.zaikio.test/api/v1/jwt_public_keys.json")
      .to_return(status: 200, body: {
        keys: [JWT::JWK::RSA.new(dummy_private_key.public_key).export]
      }.to_json)

    stub_request(:get, "http://directory.zaikio.test/api/v1/blacklisted_access_tokens.json")
      .to_return(status: 200, body: {
        blacklisted_token_ids: %w[bad-token very-bad-token]
      }.to_json)
  end
end
